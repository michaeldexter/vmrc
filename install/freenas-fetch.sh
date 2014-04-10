#!/bin/sh
# $Version: v.1.0-BETA10$

# Copyright (c) 2013-2014 Michael Dexter <editor@callfortesting.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF

# This script prepares a recent FreeNAS "img" image for use with bhyve.

# USAGE
#
# sh freenas-fetch.sh
#
# Very quick, very dirty
#
# CAUTION: This will forcibly unmount and use /mnt

ISOSITE="http://cdn.freenas.org/9.2.1/RELEASE/x64/"
ISOIMG="FreeNAS-9.2.1-RELEASE-x64.img.xz"
DISTFILES="/usr/local/vm/distributions/freenas/"

# Read the first 29 characters of FreeNAS-9.2.0-RELEASE-x64.img.xz
# to give us FreeNAS-9.2.1-RELEASE-x64.img  KLUGE!!!

EXPANDED=$(echo FreeNAS-9.2.1-RELEASE-x64.img.xz | cut -c 1-29)


if [ ! -f $DISTFILES$ISOIMG ]; then
	echo "Fetching $ISOIMG"
	mkdir -p $DISTFILES
	fetch $ISOSITE$ISOIMG -o $DISTFILES
fi

if [ ! -f $DISTFILES$EXPANDED ]; then
	echo "Expanding $ISOIMG"
	unxz --keep $DISTFILES$ISOIMG
fi

echo "Copying $ISOIMG to freenas4.img"
cp $DISTFILES$EXPANDED $DISTFILES/freenas4.img

MNT=/mnt

echo "Force unmounting $MNT"
echo ""
umount -f $MNT

echo "Preparing disk image freenas4.img"
echo ""
MD=$( mdconfig -af $DISTFILES/freenas4.img )
echo "$MD"

echo "Running mdconfig -lv"
echo ""
mdconfig -lv

echo "Running fsck_ufs on /dev/$MD"s1a""
echo ""
fsck_ufs -y /dev/$MD"s1a"

echo "Mounting /dev/$MD"s1a" on $MNT"
echo ""
mount /dev/$MD"s1a" $MNT

echo "Running mount"
echo ""
mount

echo "Backing up the original /etc/ttys"
echo "Running cp $MNT/etc/ttys $MNT/etc/ttys.orig"
echo ""
cp $MNT/etc/ttys $MNT/etc/ttys.orig

echo "Enabling the required console"
echo ""

cat >> $MNT/etc/ttys << EOF
console "/usr/libexec/getty freenas"   vt100   on   secure
EOF

echo "Running tail $MNT/etc/ttys"
echo ""
tail $MNT/etc/ttys

echo "Unmounting $MNT"
echo ""
umount $MNT

echo "Running mount"
echo ""
mount

echo "Destroying $MD"
mdconfig -du $MD

echo "Running mdconfig -lv"
mdconfig -lv

echo "Creating the freenas4 directory tree"
mkdir -p /usr/local/vm/freenas4

echo "ln -s $DISTFILES/freenas4.img /usr/local/vm/freenas4/freenas4.img"
ln -s $DISTFILES/freenas4.img /usr/local/vm/freenas4/freenas4.img
