#!/bin/bash

HOST='mc.monkechat.com'
USER='nate'
REMOTE_USER='minecraft'

SERVER_DIR='/opt/minecraft/server'
LIB_DIR='/var/lib/minecraft'
LOG_DIR='/var/log/minecraft'

echo "Deploying to $HOST..."
scp startup.sh $USER@$HOST:/tmp/startup.sh
scp logrotate.sh $USER@$HOST:/tmp/logrotate.sh
scp logscrape.py $USER@$HOST:/tmp/logscrape.py
scp logsend.sh $USER@$HOST:/tmp/logsend.sh

echo "Placing files..."
ssh $USER@$HOST 2> /dev/null << EOF
    set -e
    sudo mv /tmp/startup.sh $SERVER_DIR/startup.sh
    sudo mv /tmp/logrotate.sh $SERVER_DIR/logrotate.sh
    sudo mv /tmp/logscrape.py $LIB_DIR/logscrape.py
    sudo mv /tmp/logsend.sh $LIB_DIR/logsend.sh

    sudo chown $REMOTE_USER:$REMOTE_USER $SERVER_DIR/startup.sh
    sudo chmod 0754 $SERVER_DIR/startup.sh

    sudo chown $REMOTE_USER:$REMOTE_USER $SERVER_DIR/logrotate.sh
    sudo chmod 0754 $SERVER_DIR/logrotate.sh

    sudo chown $REMOTE_USER:$REMOTE_USER $LIB_DIR/logscrape.py
    sudo chmod 0754 $LIB_DIR/logscrape.py

    sudo chown $REMOTE_USER:$REMOTE_USER $LIB_DIR/logsend.sh
    sudo chmod 0754 $LIB_DIR/logsend.sh

    sudo rm -f /tmp/startup.sh
    sudo rm -f /tmp/logrotate.sh
    sudo rm -f /tmp/logscrape.py
    sudo rm -f /tmp/logsend.sh
EOF

echo "Done."
