#!/bin/bash
# to be run by jenkins. Optional argument is branch name

set -euo pipefail

test -n "$GIT_COMMIT" && revision=`echo $GIT_COMMIT | cut -c1-10`
test -n "$GIT_BRANCH" && branch=`echo $GIT_BRANCH | sed 's!^origin/!!'`

./bootstrap.sh
test -n $branch && branch=${1:-master}
date=`env TZ=GMT date +%Y%m%d`
test -n "$revision" && revision=`git rev-parse --short ${branch}`
package_version=`grep "^ *PACKAGE_VERSION=" configure | sed "s/.*=//;s/'//g"`
version="${package_version%-VCS}"
suffix="${date}-r${revision}"
mkdir -p artifacts

./test-builds.sh --cleanup layer-00-default layer-01-minimal layer-02-maximus || exit 1

# sources
./configure --silent --enable-build-info="DATE: ${date} REVISION: ${revision}" --enable-translation
make -s dist-all
ln squid-${package_version}.tar.bz2 artifacts/squid-${version}-${suffix}.tar.bz2
ln squid-${package_version}.tar.gz artifacts/squid-${version}-${suffix}.tar.gz

# cfgman
mkdir -p doc/cfgman
./scripts/www/build-cfg-help.pl --version ${version} -o doc/cfgman src/cf.data
(cd  doc/cfgman; tar -zcf ../../artifacts/squid-${version}-${suffix}-cfgman.tar.gz *)
./scripts/www/build-cfg-help.pl --version ${version} -o artifacts/squid-${version}-${suffix}-cfgman.html -f singlehtml src/cf.data
gzip -9f artifacts/squid-${version}-${suffix}-cfgman.html

# manuals
make -C src squid.8
mkdir -p doc/man
ln `grep -rl '^.SH' src doc tools | grep '[1-9]$'` doc/man
for file in doc/man/*.[1-9]; do groff -E -Thtml -mandoc <$file >$file.html; done
(cd doc/man; tar -zcf ../../artifacts/squid-${version}-${suffix}-manuals.tar.gz *)

# langpack
(cd errors; tar -zcf ../artifacts/squid-${version}-${suffix}-langpack.tar.gz */* alias* TRANSLATORS COPYRIGHT)

# changelog
ln ChangeLog ChangeLog.txt
for file in RELEASENOTES.html ChangeLog.txt; do
	test -e $file && ln $file artifacts/squid-${version}-${suffix}-$file
done


# output files in artifacts/
