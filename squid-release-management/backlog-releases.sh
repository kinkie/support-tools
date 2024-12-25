#!/bin/bash

# run this in a directory containing squid releases tarfiles and signatures
# argument:
#    github_repo (e.g. squid-cache/squid)
#    TAGS file, containing a dump of relevant github tags

# Iterate over release tags, and for each create a release unless it already exists
# with the relevant changelog extracted from the local ChangreLog file

repo="$1"; shift
tagsfile="$1"; shift
mydir=`dirname $0`

# tags: contents of the tagsfile
# versions: array of versions in lexicographic order from list of files
# tagmap: same as tags, but associative
# vermap: version -> tag if tag exists
declare -a tags versons
declare -A tagmap vermap

ls squid-* | sed 's/squid-//;s/\.tar.*//' | sort -u > /tmp/versions
readarray -t versions </tmp/versions
rm /tmp/versions
readarray -t tags <$tagsfile

# printf "version: '%s'\n" "${versions[@]}"
printf "tag: '%s'\n" "${tags[@]}"

for t in "${tags[@]}"
do
    tagmap[$t]=$t
done

for v in "${versions[@]}"
do
    t="SQUID_${v//\./_}"
    if [ -n "${tagmap[$t]}" ] ; then
        vermap[$v]="$t"
        echo "$v -> $t"
    else
        echo "$v -> X"
    fi
done

# get a list of filenames, return a list of decporated filenames
decorate(){
    rv=""
    for f in "$@"
    do
        if [ "${f: -3}" = "asc" ] ; then
            rv+= printf " '%s#%s'" "$f" "Signature for ${f%.asc}"
        else
            rv+= printf " '%s#%s'" "$f" "Bootstrapped sources: ${f}"
        fi
    done
    echo $rv
}

for v in "${versions[@]}"
do
    # if no tag exists, add assets to HISTORIC_RELEASES
    if [ -z "${vermap[$v]}" ]; then
        assets=`decorate squid-${v}.*`
        echo gh -R $repo release upload HISTORIC_RELEASES $assets
        continue
    fi


    # # the file where to write the changelog entry for this file
    release_changelog_file=/tmp/ChangeLog-$v

    # # samplefile is the file from where to generate the changelog
    samplefile=`ls squid-${v}.tar.* | grep -v '\.asc$' | head -1`
    test -n "$samplefile" || exit 1 # leave if can't find a changelog file
    tar xvf $samplefile -O squid-$v/ChangeLog | awk 'BEGIN {flag=2} /^Changes/ {flag=flag-1} flag>0' >$release_changelog_file
    assets=`decorate squid-${v}.*`
    echo gh -R $repo release create ${vermap[$v]} -F $release_changelog_file --title "v${v}" $assets
done