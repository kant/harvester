#!/bin/bash

#
# buildpkg.sh
#
# Copyright (c) 2005-2012 Alec Smecher and John Willinsky
# Distributed under the GNU GPL v2. For full terms see the file docs/COPYING.
#
# Script to create an Open Harvester Systems package for distribution.
#
# Usage: buildpkg.sh <version> [<tag>] [<patch_dir>]
#
#

GITREP=git://github.com/pkp/harvester.git

if [ -z "$1" ]; then
	echo "Usage: $0 <version> [<tag>-<branch>] [<patch_dir>]";
	exit 1;
fi

VERSION=$1
TAG=$2
PATCHDIR=${3-}
PREFIX=ohs
BUILD=$PREFIX-$VERSION
TMPDIR=`mktemp -d $PREFIX.XXXXXX` || exit 1

EXCLUDE="dbscripts/xml/data/locale/te_ST			\
docs/dev							\
locale/te_ST							\
plugins/harvesters/junk						\
tools/buildpkg.sh						\
tools/genTestLocale.php						\
lib/pkp/tests							\
.git								\
lib/pkp/.git"

cd $TMPDIR

echo -n "Cloning $GITREP and checking out tag $TAG ... "
git clone -q -n $GITREP $BUILD || exit 1
cd $BUILD
git checkout -q $TAG || exit 1
echo "Done"

echo -n "Checking out corresponding submodule ... "
git submodule -q update --init >/dev/null || exit 1
echo "Done"

echo -n "Preparing package ... "
cp config.TEMPLATE.inc.php config.inc.php
find . \( -name .gitignore -o -name .gitmodules -o -name .keepme \) -exec rm '{}' \;
rm -rf $EXCLUDE

# Create cache directories
mkdir cache
mkdir cache/t_compile
mkdir cache/t_cache
mkdir cache/_db

echo "Done"

cd ..

echo -n "Creating archive $BUILD.tar.gz ... "
tar -zhcf ../$BUILD.tar.gz $BUILD
echo "Done"

if [ ! -z "$PATCHDIR" ]; then
	echo "Creating patches in $BUILD.patch ..."
	[ -e "../${BUILD}.patch" ] || mkdir "../$BUILD.patch"
	for FILE in $PATCHDIR/*; do
		OLDBUILD=$(basename $FILE)
		OLDVERSION=${OLDBUILD/$PREFIX-/}
		OLDVERSION=${OLDVERSION/.tar.gz/}
		echo -n "Creating patch against ${OLDVERSION} ... "
		tar -zxf $FILE
		diff -urN $PREFIX-$OLDVERSION $BUILD | gzip -c > ../${BUILD}.patch/$PREFIX-${OLDVERSION}_to_${VERSION}.patch.gz
		echo "Done"
	done
	echo "Done"
fi

cd ..
rm -r $TMPDIR
