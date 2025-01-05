#!/bin/zsh

set -o pipefail

# run this in a passing as arguments the files to be signed
# A ChangeLog file must be in the same directory for timestamps
# Failing that, an attempt is made to extract a ChangeLog

test -f "$HOME/.squidrelease.rc" && . "$HOME/.squidrelease.rc"
export GPG=gpg


# argument: the file to be signed, the release date
# sets SIGNKEY, EMAIL, GPGHOME. May set other variables
signfiles() {
    local file=$1
    local releasedate=`date -R -u -d "$2"`
    local signdate=`date -R -u`
    size="`stat $file | awk '/Size:/ {print $2;}'`"
    md5="`md5sum -b $file | awk '{print $1;}'`"
    sha1="`sha1sum -b $file | awk '{print $1;}'`"
    sha256="`sha256sum -b $file | awk '{print $1;}'`"
    fingerprint=`$GPG --fingerprint $SIGNKEY | grep -v -E -e "^[ups]" -e "^$"`
    if [ -e "$file.asc" ]; then
        echo >> $file.asc
        echo "Re-signed:" >> $file.asc
    fi
    (
        cat <<EOF
File     : $file
Date     : $releasedate
Signed on: $signdate
Size     : $size
MD5      : $md5
SHA1     : $sha1
SHA256   : $sha256
Key      : $SIGNKEY $EMAIL
Fingerprint: $fingerprint
Keyring  : https://www.squid-cache.org/pgp.asc
Keyserver: keyserver.ubuntu.com
EOF
    gpg --homedir $GPGHOME --use-agent --default-key $SIGNKEY -o- -ba $file
    ) >> $file.asc
}

for file
do
    # version=${file%.tar.xz}
    version=`echo $file | sed 's/\.tar.*//;s/^squid-//'`
    releaseddate=`grep "^Changes.*${version} " ChangeLog | sed 's/.*(//;s/).*//' | head -1`
    if [ -z "$releaseddate" ] || ! date -d "$releaseddate" >/dev/null ;  then
        releaseddate=`tar tvfz $file --wildcards \*/ChangeLog | head -1 | awk '{print $4}'`
    fi
    echo "$file - $releaseddate"
    signfiles $file $releaseddate
    touch -c -d "$releaseddate" $file $file.asc
done