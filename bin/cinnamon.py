#!/usr/bin/env python3

import json
import os

conf_dir = '/Users/bfrank/Downloads/cinnamon-new/'
applets = {
    'show-desktop@cinnamon.org/2.json': {
        'peek-at-desktop': True
    },
    'window-list@cinnamon.org/4.json': {
        'window-preview-show-label': False
    }
}

for applet,settings in applets.items():
    conf_file = os.path.join(conf_dir, applet)

    for key,value in settings.items():
        with open(conf_file) as f:
            config = json.load(f)
            config[key]['value'] = value
        with open(conf_file, 'wt') as f:
            print(json.dumps(config,
                             sort_keys=True,
                             indent=4,
                             separators=(',', ': ')),
                  file=f)
