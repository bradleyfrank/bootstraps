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

# insert plasma template
cat << EOF > "$HOME"/.config/plasma-org.kde.plasma.desktop-appletsrc
[ActionPlugins][0]
MidButton;NoModifier=org.kde.paste
RightButton;NoModifier=org.kde.contextmenu
wheel:Vertical;NoModifier=org.kde.switchdesktop

[ActionPlugins][1]
RightButton;NoModifier=org.kde.contextmenu

[Containments][2]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][2][Applets][1]
immutability=1
plugin=org.kde.plasma.kicker

[Containments][2][Applets][1][Configuration]
PreloadWeight=100

[Containments][2][Applets][1][Configuration][General]
favoritesPortedToKAstats=true
icon=start-here

[Containments][2][Applets][2]
immutability=1
plugin=org.kde.plasma.pager

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.icontasks

[Containments][2][Applets][3][Configuration][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][2][Applets][3][Configuration][General]
launchers=applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop
maxStripes=1
smartLaunchersEnabled=false

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.systemloadviewer

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][5][Configuration]
PreloadWeight=75
SystrayContainmentId=3

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][2][ConfigDialog]
DialogHeight=83
DialogWidth=1280

[Containments][2][General]
AppletOrder=1;2;3;4;5;6


[Containments][3]
activityId=
formfactor=2
immutability=1
lastScreen=0
location=4
plugin=org.kde.plasma.private.systemtray
wallpaperplugin=org.kde.image

[Containments][3][Applets][9]
immutability=1
plugin=org.kde.plasma.volume

[Containments][3][Applets][10]
immutability=1
plugin=org.kde.plasma.clipboard

[Containments][3][Applets][10][Configuration]
PreloadWeight=55

[Containments][3][Applets][11]
immutability=1
plugin=org.kde.plasma.devicenotifier

[Containments][3][Applets][12][Configuration]
PreloadWeight=42

[Containments][3][Applets][13][Configuration]
PreloadWeight=42

[Containments][3][Applets][14]
immutability=1
plugin=org.kde.plasma.notifications

[Containments][3][Applets][15]
immutability=1
plugin=org.kde.plasma.printmanager

[Containments][3][Applets][15][Configuration]
PreloadWeight=60

[Containments][3][Applets][16][Configuration]
PreloadWeight=42

[Containments][3][Applets][17]
immutability=1
plugin=org.kde.plasma.battery

[Containments][3][Applets][18]
immutability=1
plugin=org.kde.plasma.networkmanagement

[Containments][3][Applets][18][Configuration]
PreloadWeight=55

[Containments][3][Applets][19]
immutability=1
plugin=org.kde.plasma.bluetooth

[Containments][3][ConfigDialog]
DialogHeight=540
DialogWidth=720

[Containments][3][General]
extraItems=org.kde.plasma.printmanager,org.kde.plasma.notifications,org.kde.plasma.bluetooth,org.kde.plasma.devicenotifier,org.kde.plasma.battery,org.kde.plasma.clipboard,org.kde.plasma.networkmanagement,org.kde.plasma.volume
hiddenItems=KOrganizer Reminder Daemon
knownItems=org.kde.plasma.keyboardindicator,org.kde.plasma.printmanager,org.kde.plasma.notifications,org.kde.plasma.mediacontroller,org.kde.plasma.bluetooth,org.kde.plasma.devicenotifier,org.kde.plasma.battery,org.kde.plasma.clipboard,org.kde.kdeconnect,org.kde.plasma.pkupdates,org.kde.plasma.networkmanagement,org.kde.plasma.volume
showAllItems=true
shownItems=org.kde.plasma.volume,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.clipboard,org.kde.plasma.networkmanagement

[General]
immutability=2

[ScreenMapping]
itemsOnDisabledScreens=
EOF
