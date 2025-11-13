#!/usr/bin/env bash


if [[ -f "$HOME/.env.sh" ]]; then
    source "$HOME/.env.sh"
fi

BACK_TO_EXIT=false

NEOVIM_CONF_DIR="$DOTFILES/nvim/lua/config"
NEOVIM_PLUG_DIR="$DOTFILES/nvim/lua/plugins"
HYPRLAND_CONF_DIR="$DOTFILES/hypr/config"
ZSH_CONF_DIR="$DOTFILES/zsh"
TMUX_CONF="$DOTFILES/tmux/tmux.conf"

# Prevent from opening two instances of wofi
if pgrep -x wofi >/dev/null; then
    pkill -x wofi
fi

back_to() {
  local parent_menu="$1"

  if [[ "$BACK_TO_EXIT" == "true" ]]; then
    exit 0
  elif [[ -n "$parent_menu" ]]; then
    "$parent_menu"
  else
    show_main_menu
  fi
}


menu() {
    local prompt="$1"
    local options="$2"
    local height="${3:-}"
    local width="${4:-}"

    local args=("-S" "dmenu" "-p" "$prompt")

    [[ -n "$height" ]] && args+=("-H" "$height")
    [[ -n "$width" ]] && args+=("-W" "$width")

    echo -e "$options" | wofi "${args[@]}"
}

terminal(){
    exec setsid uwsm-app -- xdg-terminal-exec -e "$@"
}

floating_terminal(){
    exec setsid uwsm-app -- xdg-terminal-exec --app-id=FloatingTerm -e "$@"
}

open_in_vim(){
    notify-send "Editing config file" "$1"
    terminal nvim $1
}

get_hostname_config() {
    local file="$1"
    local path
    path=$(awk -F= '/^source/ {gsub(/^ */,"",$2); print $2}' "$file")
    eval echo "$path"
}

go_to_menu() {
    case "${1,,}" in
        *apps*) app-launcher;;
        *screenshot*) show_screenshot_menu;;
        *console*) console-mode;;
        *whichkey*) keybindings;;
        *wallpapers*) wallpapers;;
        *clipboard*) clipboard;;
        *utils*) show_utils_menu;;
        *dotfiles*) floating_terminal lazygit -p $DOTFILES;;
        *settings*) show_settings_menu;;
        *install*) floating_terminal install-pkg;;
        *remove*) floating_terminal remove-pkg;;
        *update*) floating_terminal update-pkg;;
        *system*) show_system_menu ;;
    esac
}

show_main_menu() {
    go_to_menu "$(menu "Welcome" "󰀻  Apps\n  Utils\n  Dotfiles\n󰉉  Install\n󰭌  Remove\n  Update\n  Settings\n  System" "340")"
}

show_utils_menu() {
    case $(menu "Screenshot" "  Screenshot\n  Whichkey\n  Clipboard\n  Wallpapers\n  Console Mode" "220") in
        *Screenshot*) show_screenshot_menu;;
        *Whichkey*) keybindings;;
        *Clipboard*) clipboard;;
        *Console*) console-mode;;
        *Wallpapers*) wallpapers;;
        *) back_to show_main_menu;;
    esac
}

show_screenshot_menu() {
    case $(menu "Screenshot" "  Region\n  Window\n󰍹  Monitor" "140") in
        *Region*) uwsm-app -- hyprshot -m region --clipboard-only;;
        *Window*) uwsm-app -- hyprshot -m window --clipboard-only;;
        *Monitor*) uwsm-app -- hyprshot -m output --clipboard-only;;
        *) back_to show_utils_menu;;
    esac
}

show_settings_menu(){
    case $(menu "Settings" "  Sound\n󰛳  Network\n  Hyprland\n  Neovim\n  Zsh\n  Tmux" "260") in
        *Sound*) floating_terminal wiremix;;
        *Network*) show_network_menu;;
        *Hyprland*) show_hyprland_menu;;
        *Neovim*) show_neovim_menu;;
        *Zsh*) show_zsh_menu;;
        *Tmux*) open_in_vim $TMUX_CONF;;
        *) back_to show_main_menu;;
    esac
}

show_zsh_menu() {
    case $(menu "Zsh" "  Zshrc\n  Zprofile\n  Aliases") in
        *Zshrc*) open_in_vim $ZSH_CONF_DIR/rc.zsh;;
        *Zprofile*) open_in_vim $ZSH_CONF_DIR/profile.zsh;;
        *Aliases*) open_in_vim $ZSH_CONF_DIR/aliases.zsh;;
        *) back_to show_settings_menu;;
    esac
}

show_network_menu() {
    case $(menu "Network" "  Wifi\n󰂯  Bluetooth\n  Network configuration") in
        *Wifi*) show_neovim_menu;;
        *Bluetooth*) blueberry;;
        *Network*) nm-connection-editor;;
        *) back_to show_settings_menu;;
    esac
}

show_hyprland_menu(){
    case $(menu "Hyprland" "  Keybindings\n  Inputs\n󰍹  Monitors\n  LookAndFeel\n  Autostart\n󱃼  Envs\n  Windows") in
        *Keybindings*) open_in_vim $HYPRLAND_CONF_DIR/bindings.conf;;
        *Inputs*) open_in_vim $HYPRLAND_CONF_DIR/input.conf;;
        *Monitors*) open_in_vim $(get_hostname_config $HYPRLAND_CONF_DIR/monitors.conf);;
        *LookAndFeel*) open_in_vim $HYPRLAND_CONF_DIR/looknfeel.conf;;
        *Autostart*) open_in_vim $HYPRLAND_CONF_DIR/autostart.conf;;
        *Envs*) open_in_vim $HYPRLAND_CONF_DIR/envs.conf;;
        *Windows*) open_in_vim $HYPRLAND_CONF_DIR/windows.conf;;
        *) back_to show_settings_menu;;
    esac

}

show_neovim_menu(){
    case $(menu "Neovim" "  Keybindings\n󰒲  Lazy\n  Options\n  AutoCmds\n󰏓  Plugins") in
        *Keybindings*) open_in_vim $NEOVIM_CONF_DIR/remaps.lua;;
        *Options*) open_in_vim $NEOVIM_CONF_DIR/options.lua;;
        *Lazy*) open_in_vim $NEOVIM_CONF_DIR/lazy.lua;;
        *AutoCmds*) open_in_vim $NEOVIM_CONF_DIR/autocmds.lua;;
        *Plugins*) open_in_vim $NEOVIM_PLUG_DIR;;
        *) back_to show_settings_menu;;
    esac
}

show_system_menu(){
      case $(menu "System" "  Lock\n󰤄  Suspend\n󰜉  Restart\n󰐥  Shutdown" "180" "300") in
        *Lock*) uwsm-app hyprlock ;;
        *Logout*) uwsm stop ;;
        *Suspend*) systemctl suspend;;
        *Restart*) systemctl reboot ;;
        *Shutdown*) systemctl poweroff ;;
        *) back_to show_main_menu ;;
    esac
}

if [[ -n "$1" ]]; then
  BACK_TO_EXIT=true
  go_to_menu "$1"
else
  show_main_menu
fi
