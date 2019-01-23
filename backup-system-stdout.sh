#!/bin/bash -x
set -euo pipefail

test -f $0.local && . $0.local

#declarations
cleanstate=""
rm_tmp_state=""
exclusions=${exclusions:-}
ilabel=" (full)"
statefile=${statefile:-/usr/local/lib/backup.state}
incremental="--listed-incremental=$statefile"

TEMP=`/usr/bin/getopt -o h --long help,novm,full,cleanstate -- "$@"`
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

mountpoints_detected=$(mount | grep -e 'type \(ext\|btrfs\)'|awk '{print $3}'|grep -v -e '^/media' -e '^/mnt/' -e '/tmp' | lsort)
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
        cp "$statefile" "$statefile.saved"
        rm_tmp_state=yes
    fi
    
    ilabel="  (incr)"
fi


echo -n "backing up${ilabel} " >&2
echo ${mountpoints:=$mountpoints_detected} >&2

# 

tar -C / -c --ignore-case -f - -v --totals --label="Backup ${hostname} ${date}${ilabel}" $exclusions $incremental --one-file-system $mountpoints

if [ -n "$rm_tmp_state" -a -f "$statefile.saved" ]; then
    echo "mv $statefile.saved $statefile" >&2
    mv $statefile.saved $statefile
fi
