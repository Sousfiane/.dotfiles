#!/usr/bin/env python3
"""Events from a CalDAV server (Nextcloud) as JSON, for the hub.

usage: calendar.py START END       (YYYY-MM-DD, END exclusive)

The server, user and app password all come from the keyring, so none of them are in the dotfiles:
    secret-tool store --label="Nextcloud calendar" service nextcloud-caldav url https://cloud.example.com user USER

Recurring events are expanded by the server. Prints
    {"calendars": [{"name", "color"}], "events": [{"calendar", "color", "title",
     "location", "start", "end", "allDay"}]}
with local ISO times, or {"error": "..."} and exits 1.
"""

import base64
import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

NS = {
    "d": "DAV:",
    "c": "urn:ietf:params:xml:ns:caldav",
    "a": "http://apple.com/ns/ical/",
}


def fail(msg):
    print(json.dumps({"error": msg}))
    sys.exit(1)


def secret_tool(*args):
    try:
        return subprocess.run(["secret-tool", *args], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired) as e:
        fail(f"keyring: {e}")


def account():
    """-> (url, user, password) from the keyring item with service=nextcloud-caldav"""
    out = secret_tool("search", "--all", "--unlock", "service", "nextcloud-caldav")
    # one block per item: "[/org/freedesktop/secrets/...]" then "key = value" lines
    # (attributes go to stderr on some libsecret versions, so read both)
    items, cur = [], None
    for line in (out.stdout + "\n" + out.stderr).splitlines():
        if line.startswith("["):
            cur = {}
            items.append(cur)
        elif cur is not None and " = " in line:
            k, _, v = line.partition(" = ")
            cur[k.strip()] = v.strip()
    for item in items:
        url, user = item.get("attribute.url"), item.get("attribute.user")
        if url and user:
            pw = secret_tool("lookup", "service", "nextcloud-caldav", "url", url, "user", user)
            if pw.returncode == 0 and pw.stdout:
                return url.rstrip("/"), user, pw.stdout.rstrip("\n")
    fail("no Nextcloud account in the keyring (see secret-tool store in calendar.py)")


def request(method, url, auth, body, depth):
    req = urllib.request.Request(url, data=body.encode(), method=method, headers={
        "Authorization": "Basic " + auth,
        "Content-Type": "application/xml; charset=utf-8",
        "Depth": depth,
        "User-Agent": "quickshell-calendar",    # the default Python-urllib agent gets a 403
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return ET.fromstring(r.read())
    except urllib.error.HTTPError as e:
        fail("wrong user or app password" if e.code == 401 else f"HTTP {e.code}")
    except (urllib.error.URLError, TimeoutError) as e:
        fail(f"cannot reach the server ({getattr(e, 'reason', e)})")


def calendars(base, user, auth):
    home = f"{base}/remote.php/dav/calendars/{urllib.parse.quote(user)}/"
    root = request("PROPFIND", home, auth, """<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:a="http://apple.com/ns/ical/">
  <d:prop><d:resourcetype/><d:displayname/><a:calendar-color/><c:supported-calendar-component-set/></d:prop>
</d:propfind>""", "1")
    out = []
    for resp in root.findall("d:response", NS):
        prop = resp.find("d:propstat/d:prop", NS)
        if prop is None or prop.find("d:resourcetype/c:calendar", NS) is None:
            continue
        comps = [c.get("name") for c in prop.findall("c:supported-calendar-component-set/c:comp", NS)]
        if comps and "VEVENT" not in comps:
            continue                    # task-only lists
        href = resp.findtext("d:href", namespaces=NS)
        color = (prop.findtext("a:calendar-color", namespaces=NS) or "").strip()
        out.append({
            "url": urllib.parse.urljoin(base, href),
            "name": prop.findtext("d:displayname", namespaces=NS) or href.rstrip("/").split("/")[-1],
            "color": color[:7] if color.startswith("#") else "",   # #rrggbbaa -> #rrggbb
        })
    return out


def unescape(s):
    return s.replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def parse_dt(params, value):
    """-> (aware datetime or date, all_day)"""
    if params.get("VALUE") == "DATE" or (len(value) == 8 and value.isdigit()):
        return date(int(value[:4]), int(value[4:6]), int(value[6:8])), True
    dt = datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
    if value.endswith("Z"):
        dt = dt.replace(tzinfo=timezone.utc)
    elif "TZID" in params:
        try:
            dt = dt.replace(tzinfo=ZoneInfo(params["TZID"]))
        except Exception:
            dt = dt.astimezone()        # unknown zone: take it as local
    else:
        dt = dt.astimezone()            # floating time: local
    return dt, False


def parse_duration(v):
    sign = -1 if v.startswith("-") else 1
    v = v.lstrip("+-").lstrip("P")
    days = secs = 0
    num = ""
    in_time = False
    for ch in v:
        if ch.isdigit():
            num += ch
            continue
        if ch == "T":
            in_time = True
            continue
        n = int(num or 0)
        num = ""
        if ch == "W":
            days += 7 * n
        elif ch == "D":
            days += n
        elif ch == "H" and in_time:
            secs += 3600 * n
        elif ch == "M" and in_time:
            secs += 60 * n
        elif ch == "S" and in_time:
            secs += n
    return sign * timedelta(days=days, seconds=secs)


def events(ics, cal):
    # unfold continuation lines
    lines = []
    for raw in ics.replace("\r\n", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        elif raw:
            lines.append(raw)

    out = []
    ev = None
    depth = 0                           # skip nested components (VALARM)
    for line in lines:
        if line == "BEGIN:VEVENT":
            ev, depth = {}, 0
            continue
        if ev is None:
            continue
        if line.startswith("BEGIN:"):
            depth += 1
            continue
        if line.startswith("END:") and depth:
            depth -= 1
            continue
        if line == "END:VEVENT":
            out.append(ev)
            ev = None
            continue
        if depth:
            continue
        name, _, value = line.partition(":")
        key, *rest = name.split(";")
        params = dict(p.split("=", 1) for p in rest if "=" in p)
        params = {k.upper(): v.strip('"') for k, v in params.items()}
        ev[key.upper()] = (params, value)

    result = []
    for ev in out:
        if "DTSTART" not in ev or ev.get("STATUS", ({}, ""))[1].upper() == "CANCELLED":
            continue
        start, all_day = parse_dt(*ev["DTSTART"])
        if "DTEND" in ev:
            end, _ = parse_dt(*ev["DTEND"])
        elif "DURATION" in ev:
            end = start + parse_duration(ev["DURATION"][1])
        else:
            end = start + timedelta(days=1) if all_day else start
        if all_day:
            s, e = start.isoformat(), end.isoformat()
        else:
            s, e = start.astimezone().isoformat(), end.astimezone().isoformat()
        result.append({
            "calendar": cal["name"],
            "color": cal["color"],
            "title": unescape(ev.get("SUMMARY", ({}, "(no title)"))[1]),
            "location": unescape(ev.get("LOCATION", ({}, ""))[1]),
            "start": s,
            "end": e,
            "allDay": all_day,
        })
    return result


def main():
    if len(sys.argv) != 3:
        fail("usage: calendar.py START END")
    start, end = sys.argv[1], sys.argv[2]
    base, user, pw = account()
    auth = base64.b64encode(f"{user}:{pw}".encode()).decode()

    # the range in UTC, as CalDAV wants it
    def utc(d):
        return datetime.fromisoformat(d).astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    t0, t1 = utc(start), utc(end)

    cals = calendars(base, user, auth)
    evs = []
    for cal in cals:
        root = request("REPORT", cal["url"], auth, f"""<?xml version="1.0"?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop><c:calendar-data><c:expand start="{t0}" end="{t1}"/></c:calendar-data></d:prop>
  <c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">
    <c:time-range start="{t0}" end="{t1}"/>
  </c:comp-filter></c:comp-filter></c:filter>
</c:calendar-query>""", "1")
        for data in root.iter("{urn:ietf:params:xml:ns:caldav}calendar-data"):
            if data.text:
                evs += events(data.text, cal)

    evs.sort(key=lambda e: (e["start"][:10], not e["allDay"], e["start"]))
    print(json.dumps({
        "calendars": [{"name": c["name"], "color": c["color"]} for c in cals],
        "events": evs,
    }))


if __name__ == "__main__":
    main()
