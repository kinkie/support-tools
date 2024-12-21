#!/bin/bash

if [ $# -lt 1 ]; then
    echo "use: $0 <new version> [ChangeLog file]"
    exit 1
fi

new_version=$1
shift
awk "/^Changes (in|to) squid-${new_version} /{flag=2} /^$/{flag=flag-1; next} flag>0" ${1:-ChangeLog} | sed 's/^[ 	]*-/ */'
