#!/bin/bash

# set default terminal profile
kwriteconfig5 --file konsolerc --group 'Desktop Entry' --key DefaultProfile 'Brads-Terminal.profile'

# set Dolphin click behavior to double-click
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick 'false'

# set caps lock to control
kwriteconfig5 --file kxkbrc --group Layout --key Options 'ctrl:nocaps'