#!/usr/bin/env python3
# The installed games of Steam and Heroic with their cover art, for the dock and the workspace panel
# (services/Games.qml), which match a game's window to one of them and show its art as the icon.
#
# Prints a JSON list of {"name", "art", "steam"}: "steam" is the Steam app id (a Proton game's window
# class is steam_app_<id>), null for Heroic; "art" is a local image path, or for a Heroic game whose
# art is not cached yet its URL.

import glob
import hashlib
import json
import os
import re

HOME = os.path.expanduser("~")


# ---------- Steam ----------

STEAM_ROOTS = [f"{HOME}/.local/share/Steam", f"{HOME}/.steam/steam", f"{HOME}/.var/app/com.valvesoftware.Steam/data/Steam"]


def vdf_values(text, key):
    return re.findall(rf'"{key}"\s+"([^"]*)"', text)


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def steam_art(root, appid):
    # the portrait cover; Steam keeps it either directly in the game's folder or in a hashed subfolder
    base = f"{root}/appcache/librarycache/{appid}"
    for pattern in ("library_600x900.jpg", "*/library_600x900.jpg", "library_capsule.jpg", "*/library_capsule.jpg"):
        found = sorted(glob.glob(f"{base}/{pattern}"))
        if found:
            return found[0]
    return None


def steam_games():
    root = next((r for r in STEAM_ROOTS if os.path.isdir(f"{r}/steamapps")), None)
    if root is None:
        return []
    libraries = {f"{root}/steamapps"}
    libraries |= {f"{p}/steamapps" for p in vdf_values(read(f"{root}/steamapps/libraryfolders.vdf"), "path")}
    games = []
    for lib in libraries:
        for manifest in glob.glob(f"{lib}/appmanifest_*.acf"):
            text = read(manifest)
            ids, names = vdf_values(text, "appid"), vdf_values(text, "name")
            if not ids or not names:
                continue
            # Proton, the runtimes and the redistributables have no cover: only games are kept
            art = steam_art(root, ids[0])
            if art:
                games.append({"name": names[0], "art": art, "steam": ids[0]})
    return games


# ---------- Heroic ----------

HEROIC_ROOTS = [f"{HOME}/.config/heroic", f"{HOME}/.var/app/com.heroicgameslauncher.hgl/config/heroic"]

# library file -> the key its list of games is under
HEROIC_LIBRARIES = {
    "sideload_apps/library.json": "games",
    "store_cache/legendary_library.json": "library",
    "store_cache/gog_library.json": "games",
    "store_cache/nile_library.json": "library",
}


def heroic_art(root, game):
    # Heroic caches every image it shows under the sha256 of its URL
    for url in (game.get("art_square"), game.get("art_cover")):
        if url:
            cached = f"{root}/images-cache/{hashlib.sha256(url.encode()).hexdigest()}"
            if os.path.isfile(cached):
                return cached
    # the icon Heroic writes when it makes a desktop shortcut
    found = glob.glob(f"{root}/icons/{glob.escape(game.get('app_name') or '')}.*")
    if found:
        return found[0]
    return game.get("art_square") or game.get("art_cover")


def heroic_games():
    games = []
    for root in HEROIC_ROOTS:
        for path, key in HEROIC_LIBRARIES.items():
            try:
                library = json.loads(read(f"{root}/{path}") or "{}").get(key) or []
            except (json.JSONDecodeError, AttributeError):
                continue
            for game in library:
                if not isinstance(game, dict) or not game.get("is_installed") or not game.get("title"):
                    continue
                if (game.get("install") or {}).get("is_dlc"):
                    continue
                art = heroic_art(root, game)
                if art:
                    games.append({"name": game["title"], "art": art, "steam": None})
    return games


print(json.dumps(steam_games() + heroic_games()))
