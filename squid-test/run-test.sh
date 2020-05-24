#!/bin/bash

basedir="`dirname $0`"
conf="$basedir/squid.conf"
squid="${1:-src/squid}"

checks=$(cat <<_EOF
http://www.facebook.com
_EOF
)

echo "Starting squid"
${squid} -f ${conf}
sleep 3
echo "starting test"
http_proxy=http://localhost:3128 https_proxy=${http_proxy} ftp_proxy=${http_proxy} \
    curl -L -v ${checks} -o /dev/null
echo "stoping squid"
${squid} -f ${conf} -k shutdown
