
# PARAMS
LOGCOUNT=10 # files
LOGDIRSIZE=1024 # KB
LOGFILE=/var/log/minecraft/out.log


# CHECKS
LOGDIR=${LOGFILE%/*}

if [ ! -d $LOGDIR ]; then
        exit
fi

if [ ! -f $LOGFILE ]; then
        exit
fi

LOGNAME=${LOGFILE##*/}
BASENAME=${LOGNAME%.*}
LOGEXT=${LOGNAME##*.}

ROTATEFILE=$LOGDIR/$BASENAME-"$(date '+%Y-%m-%d_%H-%M-%S')".$LOGEXT.tar.gz
[ $? -ne 0 ] && echo "[logrotate: $LOGDIR] ERROR: could not generate rotated filename"

# ROTATE/ARCHIVE FILE AND COMPRESS
pushd $LOGDIR > /dev/null && tar -zcf $ROTATEFILE $LOGNAME > /dev/null
popd > /dev/null
[ $? -ne 0 ] && echo "[logrotate: $LOGDIR] ERROR: could not gzip logfile"
chown minecraft.minecraft $ROTATEFILE

# TRUNCATE CURRENT LOG FILE
echo "" > $LOGFILE

# REMOVE OLD FILES
for file in $(find $LOGDIR -type f -name $BASENAME'-*.'$LOGEXT'.tar.gz' -print | sort -r | tail -n +$LOGCOUNT | xargs -r0); do
        echo "[logrotate: $LOGDIR] Over $LOGCOUNT archived logs, removing oldest: $file"
        rm -f $file
done

# CHECK DIRECTORY SIZE AND ROTATE
CURSIZE=$(du -s $LOGDIR | awk '{print $1}')
DIFFSIZE=$(($LOGDIRSIZE-$CURSIZE))

if [ $CURSIZE -lt $LOGDIRSIZE ]; then
        echo "[logrotate: $LOGDIR] Under size limit: $CURSIZE/$LOGDIRSIZE KB ($DIFFSIZE KB free)"
        exit
fi

DIFFSIZE=$((1-$DIFFSIZE))
echo "[logrotate: $LOGDIR] Need to free $DIFFSIZE KB"

for file in $(find $LOGDIR -type f -name $BASENAME'-*.'$LOGEXT'.tar.gz' -print | sort -r | xargs -r0); do
        echo "[logrotate: $LOGDIR] Removing oldest log: $file"
        rm -f $file

        NEWSIZE=$(du -s $LOGDIR | awk '{print $1}')
        echo "[logrotate: $LOGDIR] Total freed: $(($CURSIZE-$NEWSIZE)) KB, dir is $NEWSIZE/$LOGDIRSIZE KB full"
        CURSIZE=$NEWSIZE

        if [ $CURSIZE -lt $LOGDIRSIZE ]; then
                DIFFSIZE=$(($LOGDIRSIZE-$CURSIZE))
                echo "[logrotate: $LOGDIR] Finished freeing with: $CURSIZE/$LOGDIRSIZE KB ($DIFFSIZE KB free)"
                break
        fi
done
