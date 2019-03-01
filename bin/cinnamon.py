#!/usr/bin/env python3

#
# WARNING:
# Although this script is 'working' in the sense that it re-writes the json files
# with the assigned values, the json is written 'out of order' as far as the system
# is concerned, and is considered corrupt.
#

import json
import os
import sys

# cinnamon applet settings
applets = {
    'calendar@cinnamon.org': {
        'custom-format': '%a %b %e %l:%M %p'
    },
    'show-desktop@cinnamon.org': {
        'peek-at-desktop': True
    },
    'window-list@cinnamon.org': {
        'window-preview-show-label': False
    }
}

# location of cinnamon configs to modify; passed variable should be "$HOME"
cinnamon_config_dir = os.path.join(sys.argv[1], '.cinnamon/configs')

# ensure main config directory exists
if not os.path.isdir(cinnamon_config_dir):
    print('Error: Cinnamon config directory not found.')
    sys.exit()

# loop through each applet
for applet,settings in applets.items():

    # get full path to applet directory
    applet_dir = os.path.join(cinnamon_config_dir, applet)

    # ensure applet config directory exists
    if not os.path.isdir(applet_dir):
        print('Warning: ' + applet + ' not found, skipping.')
        continue

    # find json file in applet directory
    for f in os.listdir(applet_dir):
        if os.path.isfile(os.path.join(applet_dir, f)):
            json_file = f
            break

    # combine paths to config file that's being modified
    config_file = os.path.join(applet_dir, json_file)

    # loop through each applet setting to update for this config file
    for key,value in settings.items():

        # read in json file
        with open(config_file) as f:
            config = json.load(f)

            if key in config:
                config[key]['value'] = value
            else:
                print('Warning: ' + key + ' not found in ' + applet + ', skipping.')

        # write out json file
        with open(config_file, 'wt') as f:
            print(json.dumps(config,
                             sort_keys=True,
                             indent=4,
                             separators=(',', ': ')),
                  file=f)
