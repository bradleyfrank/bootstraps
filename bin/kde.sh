#!/bin/bash

# default terminal profile
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key "DefaultProfile" "Brads-Terminal.profile"

# interaction behavior is double-click
kwriteconfig5 --file kdeglobals --group "KDE" --key "SingleClick" "false"

# caps lock is control
kwriteconfig5 --file kxkbrc --group "Layout" --key "Options" "ctrl:nocaps"

# increase key repeat rates
kwriteconfig5 --file kcminputrc --group "Keyboard" --key "RepeatDelay" 140
kwriteconfig5 --file kcminputrc --group "Keyboard" --key "RepeatRate" 50.00

# make Breeze default desktop theme
kwriteconfig5 --file plasmarc --group "Theme" --key "name" "default"