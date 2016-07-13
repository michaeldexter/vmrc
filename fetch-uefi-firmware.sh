#!/bin/sh
#
################################################################ LICENSE
#
# Copyright (c) 2016 Michael Dexter <editor@callfortesting.org>
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
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
############################################################ INFORMATION
#
# Title: UEFI Firmware retrieval script
# Version: v.0.9.7
#
# A simple script to retrieve UEFI firmware binaries
#
################################################################## USAGE
#
# As root run: sh fetch-uefi.sh
#
########################################################################

# suid=$( id -u ) ; [ "$suid" = "0" ] || \
[ `id -u` -ne 0 ] && \
	{ echo Must be excuted with root privileges. Exiting ; exit 1 ; }

echo "This script will download pre-built binaries of the UEFI firmware to:"
echo "/usr/share/uefi-firmware"
echo
echo "At this time of writing, the package for this software has not been"
echo "finalized but this is the likely location of it."
echo
echo "This will not be necessary in the future. Press ANY key to continue."
read mythicalanykey

# Verify that the paths are set

[ -d /usr/share/uefi-firmware ] || \
	{ echo "/usr/share/uefi-firmware does not exist. Creatingi" ; \
	mkdir -p /usr/share/uefi-firmware ; }

fetch http://people.freebsd.org/~grehan/bhyve_uefi/BHYVE_UEFI_20160526.fd \
	-o /usr/share/uefi-firmware/

fetch http://people.freebsd.org/~grehan/bhyve_uefi/BHYVE_UEFI_CSM_20151002.fd \
	-o /usr/share/uefi-firmware/

[ -r /usr/share/uefi-firmware/BHYVE_UEFI_20160526.fd ] || \
	echo "BHYVE_UEFI_20160526.fd failed to download"

[ -r /usr/share/uefi-firmware/BHYVE_UEFI_CSM_20151002.fd ] || \
	echo "BHYVE_UEFI_CSM_20151002.fd failed to download"

echo Exiting
exit 0



