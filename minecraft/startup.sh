
# ./startup.sh [ -r ] [ <server-x-xx-x.jar> ]

server_dir=/opt/minecraft/server
jarfile=server-1.19.2.jar
logfile=/var/log/minecraft/out.log
memory=2048M
pidfile=/var/run/minecraft.pid
user=minecraft
restart_mode=0

if ! id $user > /dev/null 2>&1; then
    echo "User $user does not exist"
    exit 1
fi

if ! whoami | grep -q $user; then
    echo "You must run this script as user: $user"
    exit 1
fi

# Restart mode
if [[ ! -z $1 ]] && [[ $1 == '-r' ]]; then
    restart_mode=1
    shift 1
fi

# Set the server jar explicitly for the version
if [[ ! -z $1 ]]; then
    jarfile="$1"
    shift 1
else
    if [ ! -z $MINECRAFT_SERVER_JAR ]; then
        jarfile="$MINECRAFT_SERVER_JAR"
    fi
    echo "No jarfile specified, using $jarfile"
fi

if [ ! -z $MINECRAFT_SERVER_DIR ]; then
    server_dir="$MINECRAFT_SERVER_DIR"
fi

if [ ! -f "$server_dir/$jarfile" ]; then
    echo "Server jar not found in $server_dir/$jarfile"
    exit 1
fi

# Log
if [ -d ${logfile%/*} ]; then
        mkdir -p ${logfile%/*}
fi

# PID
if [ -d ${pidfile%/*} ]; then
        mkdir -p ${pidfile%/*}
fi

# Check server process status
if [ -f $pidfile ]; then
    printf 'Found a PID...'
    if ps -ef | grep " $(cat $pidfile) " | grep -v 'grep'; then
        echo "$(cat $pidfile) is a running process"
        if [ $restart_mode -eq 1 ]; then
            echo "Restarting..."
            sudo kill -9 $(cat $pidfile)
            if [ $? -ne 0 ]; then
                echo "Failed to kill process $(cat $pidfile)"
                exit 1
            fi
        else
            echo "Already running, exiting"
            exit 1
        fi
    else
        echo "$(cat $pidfile) is not a process"
        echo "Removing stale PID file"
        sudo rm -f $pidfile
    fi
fi

echo "Version: ${jarfile%%-*}"
echo "Log: $logfile"
echo "Starting..."

java -Xmx$memory -Xms$memory -jar "$jarfile" nogui > $logfile 2>&1 &
rc="$?"
pid="$!"

if [ $rc -ne 0 ]; then
    echo "Failed to start server, check the log: $logfile"
    exit 1
fi

echo "$pid" > $pidfile
echo "Started with PID: $pid ($pidfile)"
