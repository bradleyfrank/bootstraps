#!/bin/bash

cinnamon_conf_dir="$HOME/.cinnamon/configs"

# load Gnome and Cinnmon settings configured via dconf
dconf load / < "$1"/assets/cinnamon.dconf

# personalize toolbar clock
sed -i 's/"value": "%A %B %e, %H:%M"/"value": "%a %b %e %l:%M %p"/' \
  "$cinnamon_conf_dir"/calendar@cinnamon.org/*.json