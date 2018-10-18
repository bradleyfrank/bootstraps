#!/bin/bash

settings_app() {

  # ==== Time Machine ====

  # prevent Time Machine from prompting to use new hard drives as backup volume
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  # ==== Disk Utility ====

  # enable the debug menu in Disk Utility
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true

  # ==== Mail ====

  # show most recent messages at the top
  defaults write com.apple.mail ConversationViewSortDescending -int 1

  # ==== Safari ====

  # enable the Debug menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # enable the Develop menu
  defaults write com.apple.Safari IncludeDevelopMenu -bool true

  # enable the Web Inspector
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

  # disable Safari autofills
  defaults write com.apple.safari autofillfromaddressbook -bool false
  defaults write com.apple.safari autofillpasswords -bool false
  defaults write com.apple.safari autofillcreditcarddata -bool false
  defaults write com.apple.safari autofillmiscellaneousforms -bool false

  # ==== Terminal ====

  # make Bash 4 an available shell option
  if ! grep -q '/usr/local/bin/bash' /etc/shells; then
    sudo bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
  fi

  # set Bash 4 as default shell for user
  sudo chsh -s /usr/local/bin/bash "$(id -un)"

  # set global default Shell to Bash 4
  defaults write com.apple.Terminal Shell -string "/usr/local/bin/bash"

  # make new tabs open in default directory
  defaults write com.apple.Terminal NewTabWorkingDirectoryBehavior -int 1

  # ==== TextEdit ====

  # use Plain Text Mode as Default
  defaults write com.apple.TextEdit RichText -int 0

}


settings_desktop() {

  # show filename extensions by default
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # disable creation of .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # ==== Finder ====

  # hide icons for hard drives, servers, and removable media on the desktop"
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

  # show status bar by default
  defaults write com.apple.finder ShowStatusBar -bool true

  # show Finder breadcrumb menu
  defaults write com.apple.finder ShowPathbar -bool true

  # disable the warning before emptying the Trash
  defaults write com.apple.finder WarnOnEmptyTrash -bool false

  # disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # avoid creating .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # default view style
  defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

  # unhide ~/Library
  chflags nohidden ~/Library

  # unhide Volumes
  sudo chflags nohidden /Volumes

  # set default location for new windows
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

  # hide desktop icons
  defaults write com.apple.finder CreateDesktop -bool false

  # ==== Dock ====

  # set Dock to auto-hide
  defaults write com.apple.dock autohide -bool true

  # convert Dock to taskbar
  defaults write com.apple.dock static-only -bool true

  # disable bouncing Dock icons
  defaults write com.apple.dock no-bouncing -bool true

  # set Dock size
  defaults write com.apple.dock tilesize -int 43

  # ==== Screenshots ====

  # save screenshots to ~/Downloads
  defaults write com.apple.screencapture location ~/Downloads

  # save screenshots as PNG
  defaults write com.apple.screencapture type -string "png"

  # ==== Expose ====

  # hot corner (bottom-left): show desktop
  defaults write com.apple.dock wvous-bl-corner -int 4
  defaults write com.apple.dock wvous-bl-modifier -int 0

  # hot corner (bottom-right): screen saver
  defaults write com.apple.dock wvous-br-corner -int 5
  defaults write com.apple.dock wvous-br-modifier -int 0

  # hot corner (top-left): mission control
  defaults write com.apple.dock wvous-tl-corner -int 2
  defaults write com.apple.dock wvous-tl-modifier -int 0

  # hot corner (top-right): application windows
  defaults write com.apple.dock wvous-tr-corner -int 3
  defaults write com.apple.dock wvous-tr-modifier -int 0

  # disable automatically rearranging Spaces
  defaults write com.apple.dock mru-spaces -bool false

  # ==== Dashboard ====

  # disable Dashboard
  defaults write com.apple.dashboard mcx-disabled -boolean true

}


settings_interface() {

  # expand save panel by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # quit printer app after print jobs complete
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

}


settings_io() {

  # enable tap-to-click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.AppleMultitouchtrackpad Clicking -bool true
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  # two finger tap to right-click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRightClick -bool true

  # enable hand resting
  defaults write com.apple.AppleMultitouchtrackpad trackpadHandResting -bool true

  # pinch to zoom
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadPinch -bool true

  # two finger rotate
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRotate -bool true

  # two finger horizontal swipe between pages
  defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true

  # three finger horizontal swipe between pages
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1
  defaults write com.apple.AppleMultitouchtrackpad TrackpadThreeFingerHorizSwipeGesture -int 1

  # show Notification Center with two finger swipe from fight edge
  defaults write com.apple.AppleMultitouchtrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3

  # smart zoom
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadTwoFingerDoubleTapGesture -int 1

  # three finger tap to look up
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadThreeFingerTapGesture -int 2

  # set very low key repeat rates
  defaults write NSGlobalDomain InitialKeyRepeat -int 25
  defaults write NSGlobalDomain KeyRepeat -int 1

  # increase power/bandwidth supplied to the BluetoothAudioAgent
  sudo defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Max (editable)" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Apple Initial Bitpool (editable)" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Apple Initial Bitpool Min (editable)" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Max" 80
  sudo defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Min" 80

}


settings_system() {

  # ==== Security ====

  # require password as soon as screensaver or sleep mode starts
  defaults write com.apple.screensaver askForPassword -int 1

  # grace period for requiring password to unlock
  defaults write com.apple.screensaver askForPasswordDelay -int 5

  # enable firewall
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

  # check for software updates daily
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  # require admin to make system preference changes
  sysprefs=$(mktemp)
  security authorizationdb read system.preferences > "$sysprefs" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :shared false" "$sysprefs"
  security authorizationdb write system.preferences < "$sysprefs" 2>/dev/null

  # enable FileVault
  if ! fdesetup isactive >/dev/null 2>&1; then
    sudo fdesetup enable -user "$USER"
  fi

  # ==== Services ====

  # enable locate database
  sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist

  # ==== Power ====

  # set screensaver idle time
  defaults -currentHost write com.apple.screensaver idleTime 300

  # put display to sleep after 15 minutes of inactivity
  sudo pmset displaysleep 15

  # put computer to sleep after 30 minutes of inactivity
  sudo pmset sleep 30

}


settings_app
settings_desktop
settings_interface
settings_io
settings_system

# restart services to apply changes
sudo killall Dock
sudo killall coreaudiod
