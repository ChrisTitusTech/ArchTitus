#!/usr/bin/env bash

# get internet connection
printf 'station wlan0 connect "Krosse Krabbe 5GHz"\nsehrkomplex\nquit\n' | iwctl

# init extensions
init-extension () {
    # enables extensions and links to gsettings
    gnome-extensions enable $1 || echo "could not enable $1"
    files=`ls ~/.local/share/gnome-shell/extensions/$1/schemas/`
    for file in $files; do
        if [[ $file == *.xml ]]; then
            echo "$file"
            sudo cp ~/.local/share/gnome-shell/extensions/$1/schemas/$file /usr/share/glib-2.0/schemas/
        fi
    done;
}
init-extension clipboard-indicator@tudmotu.com
init-extension impatience@gfxmonk.net
init-extension material-shell@papyelgringo
init-extension Vitals@CoreCoding.com
init-extension unite@hardpixel.eu
init-extension extension-list@tu.berry
init-extension sound-output-device-chooser@kgshank.net
init-extension gnome-shell-screenshot@ttll.de

# compile schemas (which are linked)
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/