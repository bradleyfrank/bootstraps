#!/bin/bash

# default terminal profile
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key "DefaultProfile" "Brads-Terminal.profile"

# interaction behavior is double-click
kwriteconfig5 --file kdeglobals --group "KDE" --key "SingleClick" "false"

# caps lock is control
kwriteconfig5 --file kxkbrc --group "Layout" --key "Options" "ctrl:nocaps"