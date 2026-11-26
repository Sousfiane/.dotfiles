package.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. package.path

require("config.monitors")
require("config.autostart")
require("config.envs")
require("config.looknfeel")
require("config.theme_files") -- hyprtoolkit and qt6ct, written from theme.json
require("config.input")
require("config.bindings")
require("config.rules")
require("config.plugins")
