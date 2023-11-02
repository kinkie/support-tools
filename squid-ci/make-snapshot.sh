#!/bin/bash
# to be run by jenkins. Optional argument is branch name

set -euo pipefail

./bootstrap.sh
branch=${1:-master}
date=`env TZ=GMT date +%Y%m%d`
revision=`git rev-parse --short ${branch}`
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
mkdir -p doc/manuals
ln $(find * -name '*.[18]') doc/manuals
for file in doc/manuals/*.[18]; do groff -E -Thtml -mandoc <$file >$file.html; done
(cd doc/manuals; tar -zcf ../../artifacts/squid-${version}-${suffix}-manuals.tar.gz *.html *.1 *.8)

# langpack
(cd errors; tar -zcf ../artifacts/squid-${version}-${suffix}-langpack.tar.gz */* alias* TRANSLATORS COPYRIGHT)

# changelog
ln ChangeLog ChangeLog.txt
for file in RELEASENOTES.html ChangeLog.txt; do
	test -e $file && ln $file artifacts/squid-${version}-${suffix}-$file
done


# output files in artifacts/
