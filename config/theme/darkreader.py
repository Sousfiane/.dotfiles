#!/usr/bin/env python3
# Dark Reader in Zen, in the current palette: its page background and text from the palette's base and
# text, dark or light as the palette is. apply.sh runs it only while Zen is closed (when Zen is open, as Zen
# restarts for its own theme), since Dark Reader reads its settings once as it starts and saves over them.
#
# They're in the profile's storage-sync-v2.sqlite (extension storage.sync), where Dark Reader loads them
# from while "Synchronize settings" is on, its default. Only the theme's colours and mode change; the rest
# (sites, per-site themes) stays. The change counter goes up so Zen Sync carries it to other devices too.
# The colour scheme's name, which its popup shows, is Dark Reader's own when one has these colours (Rosé
# Pine: dark is Rosé Pine, light is Dawn), the palette's otherwise.
#
#   darkreader.py <palette.json>

import configparser
import json
import os
import sqlite3
import sys
import zipfile

EXT = "addon@darkreader.org"
HOME = os.path.expanduser("~")


def profiles():
    # each profile listed in Zen's profiles.ini that has been opened (it has a prefs.js)
    for root in (f"{HOME}/.config/zen", f"{HOME}/.zen"):
        ini = configparser.RawConfigParser()
        if not ini.read(f"{root}/profiles.ini"):
            continue
        for section in ini.sections():
            path = ini.get(section, "Path", fallback=None)
            if not path:
                continue
            if ini.get(section, "IsRelative", fallback="1") == "1":
                path = os.path.join(root, path)
            if os.path.isfile(f"{path}/prefs.js"):
                yield path


def builtin_scheme(profile, which, bg, fg):
    # the name of Dark Reader's own colour scheme with these colours (its config/color-schemes.drconf:
    # blocks of a name, then DARK and LIGHT with a background and a text each), or None
    try:
        with zipfile.ZipFile(f"{profile}/extensions/{EXT}.xpi") as xpi:
            text = xpi.read("config/color-schemes.drconf").decode()
    except (OSError, KeyError, zipfile.BadZipFile):
        return None
    for block in text.split("=" * 32):
        lines = [line.strip() for line in block.strip().splitlines() if line.strip()]
        if not lines:
            continue
        name, section, colors = lines[0], None, {}
        for line in lines[1:]:
            if line in ("DARK", "LIGHT"):
                section = line
            elif section and ":" in line:
                key, value = (s.strip() for s in line.split(":", 1))
                colors[(section, key)] = value.lower()
        if colors.get((which, "background")) == bg.lower() and colors.get((which, "text")) == fg.lower():
            return name
    return None


def main():
    with open(sys.argv[1]) as f:
        palette = json.load(f)
    dark = palette.get("dark", True)
    bg, fg = palette["colors"]["base"], palette["colors"]["text"]
    which, prefix = ("DARK", "darkScheme") if dark else ("LIGHT", "lightScheme")

    for profile in profiles():
        db_path = f"{profile}/storage-sync-v2.sqlite"
        if not os.path.isfile(db_path):
            continue
        db = sqlite3.connect(db_path, timeout=5)
        try:
            row = db.execute("SELECT data FROM storage_sync_data WHERE ext_id = ?", (EXT,)).fetchone()
            if not row or not row[0]:
                continue                       # Dark Reader isn't installed in this profile
            settings = json.loads(row[0])
            if settings.get("syncSettings") is False:
                print(f"darkreader.py: {profile}: Dark Reader keeps its settings in local storage "
                      "(Synchronize settings is off): left as it is", file=sys.stderr)
                continue
            theme = settings.setdefault("theme", {})
            wanted = {
                "mode": 1 if dark else 0,
                f"{prefix}BackgroundColor": bg,
                f"{prefix}TextColor": fg,
                f"{which.lower()}ColorScheme": builtin_scheme(profile, which, bg, fg) or palette.get("name", "Custom"),
            }
            if all(theme.get(k) == v for k, v in wanted.items()):
                continue
            theme.update(wanted)
            with db:
                db.execute(
                    "UPDATE storage_sync_data SET data = ?, sync_change_counter = sync_change_counter + 1 "
                    "WHERE ext_id = ?",
                    (json.dumps(settings, ensure_ascii=False, separators=(",", ":")), EXT),
                )
        finally:
            db.close()


if __name__ == "__main__":
    main()
