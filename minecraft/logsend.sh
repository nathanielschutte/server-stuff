#!/bin/bash

# Cron script should be run as root

DEPLOY_USER='deploy-user'
TARGET_HOST='web.dev'
TARGET_DIR='/var/lib/gameserver/minecraft'
TARGET_FILE='log_data.json'

/usr/bin/python3 /var/lib/minecraft/logscrape.py
chown minecraft:minecraft /var/lib/minecraft/data.json

sudo -u $DEPLOY_USER scp /var/lib/minecraft/data.json $TARGET_HOST:/tmp/data.json
sudo -u $DEPLOY_USER ssh $TARGET_HOST 2> /dev/null << EOF
    set -e
    sudo mkdir -p $TARGET_DIR
    sudo chmod -R 2755 $TARGET_DIR
    sudo chown -R deploy-user:deploy-user $TARGET_DIR
    sudo mv /tmp/data.json $TARGET_DIR/$TARGET_FILE
    sudo chmod 0644 $TARGET_DIR/$TARGET_FILE
EOF
