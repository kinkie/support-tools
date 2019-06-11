#!/bin/bash

if [ $# -lt 2 ] ; then
    echo "$0 full|incr destination"
    exit 0
fi

case $1 in
	full|incr) : ;;
	*) echo "$0 full|incr"; exit 1;;
esac

duplicity $1 \
    --volsize 200 \
    --exclude /proc --exclude /sys \
    --exclude /var/log --exclude /mnt \
    --exclude-regexp '.*(btlayer-).*' \
    --exclude-if-present CACHEDIR.TAG \
    --progress \
    --ssl-no-check-certificate \
    --encrypt-sign-key C68E4F18 \
    / \
    $2/$(hostname -s)
