#!/bin/bash
set -euo pipefail

test -f $0.local && . $0.local

#declarations
cleanstate=""
rm_tmp_state=""
exclusions=${exclusions:-}
snap="bksnap"
bkroot="/mnt/bkroot"

statefile=${statefile:-/usr/local/lib/backup.state}
TEMP=`/usr/bin/getopt -o h --long help,novm -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
	case "$1" in
	--help|-h) echo "Use the source: $0"; exit 1;;
	--novm) exclusions="--exclude='*.img' --exclude='*.qcow2'"; shift;;
	--full) statefile=""; shift ;;
    --cleanstate) cleanstate=yes; shift ;;
	--) shift ; break ;;
	*) echo "Internal error"; exit 1;;
	esac
done

# sort by string length, short to long
lsort() {
    awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-
}
# argument: filesystem mountpoint. Returns 0 if fs is btrfs, 1 otherwise
is_btrfs() {
    mount | grep -q " on $1 type btrfs "
}

# TODO: exclude /
mountpoints_detected=$(mount | grep -e 'type \(ext\|btrfs\)'|awk '{print $3}'|grep -v -e '^/media' -e '^/mnt/' -e '/tmp' -e "^/$snap" | lsort)
mountpoints_detected_rev=$(mount | grep -e 'type \(ext\|btrfs\)'|awk '{print $3}'|grep -v -e '^/media' -e '^/mnt/' -e '/tmp' -e "^/$snap" | lsort | tac)
hostname=$(hostname -s)
rundir=$(dirname $0)
date=$(date +%Y.%m.%d)
export BZIP2='-1'
exclusions="$exclusions \
	--exclude='*tmp/*' \
	--exclude='*.log' \
	--exclude='*.err' \
	--exclude='*.log.gz' \
	--exclude='*.err.gz' \
	--exclude=.thumbnails \
	--exclude=Cache \
	--exclude=.ccache \
	--exclude-caches-under \
	--exclude-backups \
	--exclude='*.mp4' \
	--exclude='*.vmw' \
	--exclude='*.avi' \
	--exclude='*.mpg' \
	"

# deal with state file
if [ -n "$statefile" ]; then
    test -n "$cleanstate" -a -f "$statefile" && rm "$statefile"
# rename state file to deal with levels. If no state file, do nothing, otherwise
    if [ -f "$statefile" ]; then
        cp "$statefile" "$statefile.0"
        statefile="$statefile.0"
        rm_tmp_state=yes
    fi
    
    incremental="--listed-incremental=$statefile"
    ilabel="  (incr)"
fi


echo -n "backing up${ilabel} " >&2
echo ${mountpoints:=$mountpoints_detected} >&2

# 
test -d "$bkroot" || mkdir -p "$bkroot"

# for btrfs, create snapshot and mount
for fs in ${mountpoints}
do
    if is_btrfs $fs; then
        test -d $fs/$snap && btrfs subvolume delete $fs/$snap >&2
        btrfs subvolume snapshot $fs $fs/$snap >&2
        mount --bind $fs/$snap $bkroot/$fs
    else
        mount --bind $fs $bkroot/$fs
    fi
done

(cd $bkroot; tar -c --ignore-case -f - -j --label="Backup ${hostname} ${date}${ilabel}" $exclusions $incremental *)

if [ -n "$rm_tmp_state" -a -f "$statefile" ]; then
    echo "rm stale $statefile" >&2
    rm "$statefile"
fi

for fs in ${mountpoints_detected_rev}
do
    umount $bkroot/$fs
    test -d $fs/$snap && btrfs subvolume delete $fs/$snap >&2
done
