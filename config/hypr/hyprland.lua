package.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. package.path

require("config.monitors")
require("config.autostart")
require("config.looknfeel")
require("config.input")
require("config.bindings")
require("config.rules")
require("config.plugins")
