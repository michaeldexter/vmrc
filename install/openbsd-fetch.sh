#!/bin/sh
# $Version: v.1.0-BETA15$

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

# USAGE
#
# sh openbsd-fetch.sh
#
# Very quick, very dirty

ISOSITE="http://people.freebsd.org/~grehan/"
ISOIMG="flashimg.amd64-20131014.bz2"
EXPANDED="flashimg.amd64-20131014"

mkdir -p /usr/local/vm/distributions/openbsd

if [ ! -f /usr/local/vm/distributions/openbsd/$ISOIMG ]; then
	echo "Fetching $ISOIMG"
	fetch $ISOSITE$ISOIMG -o /usr/local/vm/distributions/openbsd/
fi

if [ ! -f /usr/local/vm/distributions/openbsd/$EXPANDED ]; then
	echo "Expanding $ISOIMG"
	bunzip2 --keep /usr/local/vm/distributions/openbsd/$ISOIMG
fi

echo "Copying "$EXPANDED" to /usr/local/vm/openbsd6/openbsd6.img"
cp -p "/usr/local/vm/distributions/openbsd/$EXPANDED" /usr/local/vm/openbsd6/openbsd6.img

echo
echo "The root password is test123"
echo
