#!/bin/sh
#
# GPLv2
# based on coreboot's utils/build-release
#
# Copyright 2019 Alexander Couzens <lynxis@fe80.eu>
#
# ${VERSION_TAG}: the git tag of squashfskit
# ${GPG_KEY_ID}: gpg key id (if not don't sign)

VERSION_TAG=$1
GPG_KEY_ID=$2

set -e
LC_ALL=C
LANG=C
TZ=UTC0
export LC_ALL LANG TZ

if ! tar --sort=name -cf /dev/null /dev/null 2>/dev/null ; then
        echo "Error: The installed version of tar does not support --sort"
        echo "       GNU tar version 1.28 or greater is required.  Exiting."
        exit 1
fi

# checkout
RELEASE_NAME="squashfskit-${VERSION_TAG}"
git clone https://github.com/squashfskit/squashfskit.git "$RELEASE_NAME"

cd "$RELEASE_NAME"
git fetch --tags
git checkout "${VERSION_TAG}"

# create version files
tstamp=$(git log --pretty=format:%ci -1)
unixstamp=$(git log --pretty=format:%ct -1)
gitrev=$(git log --pretty=%H -1)
printf "%s" "${VERSION_TAG}" > version
printf "%s" "${unixstamp}" > version.date
printf "%s" "${gitrev}" > version.git
cd ..

# create & sign
tar --sort=name --mtime="$tstamp" --owner=squashfskit:1000 --group=squashfskit:1000 --exclude=*/.git --exclude=*/.gitignore -cvf - "${RELEASE_NAME}" |xz -9 > "${RELEASE_NAME}.tar.xz"

if [ -n "${GPG_KEY_ID}" ]; then
        gpg2 --armor --local-user "$GPG_KEY_ID" --output "${RELEASE_NAME}.tar.xz.sig" --detach-sig "${RELEASE_NAME}.tar.xz"
fi
