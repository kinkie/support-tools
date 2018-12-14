#!/bin/bash
set -euo pipefail

test -f $0.local && . $0.local

#declarations
cleanstate=""
rm_tmp_state=""
exclusions=${exclusions:-}

statefile=${statefile:-/usr/local/lib/backup.state}
TEMP=`/usr/bin/getopt -o h --long help,novm -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"
while true; do
	case "$1" in
	--help|-h) echo "code: "; cat $0; exit 1;;
	--novm) exclusions="--exclude='*.img' --exclude='*.qcow2'"; shift;;
	--full) statefile=""; shift ;;
    --cleanstate) cleanstate=yes; shift ;;
	--) shift ; break ;;
	*) echo "Internal error"; exit 1;;
	esac
done

mountpoints_detected=$(mount | grep -e 'type \(ext3\|ext2\|ext4\|reiserfs\|xfs\|ecryptfs\)'|awk '{print $3}'|grep -v -e '^/media' -e '^/mnt/' -e '/tmp' )
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


    
echo "backing up${ilabel} ${mountpoints:-$mountpoints_detected}" >&2


#sanepath=$(echo $dir|sed 's/^\/$/\/root/;s/^\///;s/\//-/g;')
tar -c -C / --ignore-case -f - -j --one-file-system --label="Backup ${hostname} ${date}${ilabel}" $exclusions $incremental ${mountpoints:-$mountpoints_detected}

if [ -n "$rm_tmp_state" -a -f "$statefile" ]; then
    echo "rm stale $statefile" >&2
    rm "$statefile"
fi
