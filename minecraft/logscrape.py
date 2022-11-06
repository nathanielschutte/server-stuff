#!/usr/bin/python3

import re, json, os

LOG_FILE = '/var/log/minecraft/out.log'
DATA_FILE = '/var/lib/minecraft/data.json'
NO_TAG = '__no_tag__$'

LOG_COORD_PATTERN = r'^.*\[Server thread\/INFO\]: <(.+)>\s(?:(.*):?)?((?<=[, ])-?[0-9]+)[,\s]+(-?[0-9]+)[,\s]+(-?[0-9]+)\s*$'

data = {
    'coords': {},
    'users': {}
}

if os.path.isfile(DATA_FILE):
    with open(DATA_FILE, 'r') as f:
        try:
            data = json.load(f)
        except:
            pass

with open(LOG_FILE, 'r') as f:
    for line in f.readlines():
        m = re.match(LOG_COORD_PATTERN, line)
        if not m or len(m.groups()) != 5:
            continue

        log_user = m.group(1)
        log_tag = m.group(2)
        log_coords_x = m.group(3)
        log_coords_y = m.group(4)
        log_coords_z = m.group(5)

        if log_tag is None:
            log_tag = ''

        log_tag = log_tag.replace(':', '')
        log_tag = log_tag.strip()

        if not 'coords' in data:
            data['coords'] = {}

        # New user
        if not log_user in data['coords']:
            data['coords'][log_user] = {}

        # No tag, use sequence
        no_tag = False
        if log_tag == '':
            no_tag = True
            log_tag = NO_TAG
            cur_tag_num = 0
            for cur_tag in data['coords'][log_user]:
                if cur_tag.startswith(NO_TAG):
                    cur_tag_num = int(cur_tag[len(NO_TAG):])
            log_tag = NO_TAG + str(cur_tag_num + 1)

        # For untagged coords, never insert data dupes
        if no_tag:
            untagged_exists = False
            for _tags in data['coords'][log_user].values():
                for i, c in enumerate(_tags):
                    if c[0] == log_coords_x and c[1] == log_coords_y and c[2] == log_coords_z:
                        untagged_exists = True
            if untagged_exists:
                print(f'Skipping untagged duplicate: {c}')
                continue

        # Set up array for versioning
        if not log_tag in data['coords'][log_user]:
            data['coords'][log_user][log_tag] = []

        # Latest version. If it exists in a past version, make it the latest
        if len(data['coords'][log_user][log_tag]) > 0:
            exists_index = -1
            for i, c in enumerate(data['coords'][log_user][log_tag]):
                if c[0] == log_coords_x and c[1] == log_coords_y and c[2] == log_coords_z:
                    exists_index = i
                    break

            if exists_index >= 0:
                # Already the latest version, done
                if exists_index == len(data['coords'][log_user][log_tag]) - 1:
                    continue
                # Past version, remove it and readd to the end (latest)
                else:
                    del data['coords'][log_user][log_tag][exists_index]
            
        # Add new unique version
        data['coords'][log_user][log_tag].append((log_coords_x, log_coords_y, log_coords_z))

        print(f'Added {log_user}:{log_tag} = {log_coords_x},{log_coords_y},{log_coords_z} (version {len(data["coords"][log_user][log_tag])})')

with open(DATA_FILE, 'w') as f:
    json.dump(data, f, indent=4)
