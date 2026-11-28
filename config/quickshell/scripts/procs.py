#!/usr/bin/env python3
# The processes for the hub's System tab (services/SysMon.qml), in place of top: one JSON line per frame,
#   {"ghz": the cores' average clock, "procs": [{"pid", "name", "user", "cpu", "rss"}, ...]}
# busiest first. "cpu" is 0..1 of the whole CPU (all cores) since the last frame, "rss" bytes in RAM.
# Kernel threads are left out (nothing to kill there). The first frame comes after a short first sample
# so the list shows at once, then one every `interval` seconds (the first argument).

import glob
import json
import os
import pwd
import sys
import time

INTERVAL = float(sys.argv[1]) if len(sys.argv) > 1 else 1.5
LIMIT = 300
TICK = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")
NCPU = os.cpu_count() or 1
FREQS = glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")

users = {}
names = {}          # pid -> name, as a process keeps its own


def user(uid):
    if uid not in users:
        try:
            users[uid] = pwd.getpwuid(uid).pw_name
        except KeyError:
            users[uid] = str(uid)
    return users[uid]


def name(pid, comm):
    # comm is cut at 15 characters: the program's own name from its command line then
    if len(comm) < 15:
        return comm
    if pid not in names:
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                arg0 = f.read().split(b"\0", 1)[0].decode(errors="replace")
            names[pid] = os.path.basename(arg0) or comm
        except OSError:
            names[pid] = comm
    return names[pid]


def sample():
    out = {}
    for entry in os.scandir("/proc"):
        if not entry.name.isdigit():
            continue
        pid = int(entry.name)
        try:
            with open(f"/proc/{pid}/stat", "rb") as f:
                data = f.read().decode(errors="replace")
            uid = entry.stat().st_uid
        except OSError:
            continue
        lpar, rpar = data.find("("), data.rfind(")")
        f = data[rpar + 2:].split()
        # f[0] state, f[1] ppid, f[11] utime, f[12] stime, f[21] rss (pages)
        if pid == 2 or f[1] == "2":
            continue
        out[pid] = (data[lpar + 1:rpar], uid, int(f[11]) + int(f[12]), int(f[21]) * PAGE)
    return out, time.monotonic()


def ghz():
    total = n = 0
    for path in FREQS:
        try:
            with open(path) as f:
                total += int(f.read())
                n += 1
        except (OSError, ValueError):
            pass
    return round(total / n / 1e6, 2) if n else 0


def main():
    last, then = sample()
    delay = 0.25
    while True:
        time.sleep(delay)
        delay = INTERVAL
        now, at = sample()
        span = max(1e-3, (at - then) * TICK * NCPU)
        procs = []
        for pid, (comm, uid, ticks, rss) in now.items():
            prev = last.get(pid)
            cpu = (ticks - prev[2]) / span if prev and prev[2] <= ticks else 0
            procs.append({"pid": pid, "name": name(pid, comm), "user": user(uid), "cpu": round(min(1, cpu), 4), "rss": rss})
        procs.sort(key=lambda p: (p["cpu"], p["rss"]), reverse=True)
        for pid in list(names):
            if pid not in now:
                del names[pid]
        last, then = now, at
        try:
            sys.stdout.write(json.dumps({"ghz": ghz(), "procs": procs[:LIMIT]}, separators=(",", ":")) + "\n")
            sys.stdout.flush()
        except BrokenPipeError:
            return


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
