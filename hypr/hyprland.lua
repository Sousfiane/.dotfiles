package.path = os.getenv("DOTFILES") .. "/hypr/?.lua;" .. package.path

require("config.monitors")
require("config.autostart")
require("config.envs")
require("config.looknfeel")
require("config.input")
require("config.bindings")
require("config.rules")
