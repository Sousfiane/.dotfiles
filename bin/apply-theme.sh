GNOME="org.gnome.desktop.interface"

gsettings set $GNOME gtk-theme "rose-pine-gtk"
gsettings set $GNOME icon-theme "rose-pine-dawn-icons"
gsettings set $GNOME font-name "Noto Sans 11"
gsettings set $GNOME color-scheme "light-dark"

# Nautilus fix
if [[ ! -f $HOME/.config/gtk-4.0/gtk.css ]]; then
    mkdir -p $HOME/.config/gtk-4.0
    ln -s /usr/share/themes/rose-pine-gtk/gtk-4.0/gtk.css $HOME/.config/gtk-4.0
fi
