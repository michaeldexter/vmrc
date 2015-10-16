#!/bin/sh
#
################################################################ LICENSE
#
# Copyright (c) 2012-2014 Michael Dexter <editor@callfortesting.org>
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
# Title: virtual machine rc script uefi installation script
# Version: v.0.9
#
# Verbose script to install the vmrc rc uefi support files
#
################################################################## USAGE
#
# As root: sh install-vmrc.sh
#
########################################################################

# Keep in sync with /usr/local/vm.conf
vmrc_root="/vmrc/"   # Directory for all vmrc components

mkdir -p $vmrc_root/isos
[ -d $vmrc_root/isos ] || \
	{ echo "Directory creation failed. Exiting" ; exit 1 ; }

mkdir $vmrc_root/bhyve_uefi
[ -d $vmrc_root/bhyve_uefi ] || \
        { echo "Directory creation failed. Exiting" ; exit 1 ; }

which git >/dev/null 2>&1
exitcode=$?

if [ $exitcode = 0 ]; then
	echo git cloning the Windows Unattended XML files
	git clone https://github.com/nahanni/bhyve-windows-unattend-xml \
		$vmrc_root/bhyve-windows-unattend-xml
	[ -d $vmrc_root/bhyve-windows-unattend-xml ] || \
		{ echo "git clone failed. Exiting" ; exit 1 ; }
else
	echo "git is not installed. Exiting" ; exit 1
fi

echo Fetching the Red Had VirtIO ISO
fetch https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.96/virtio-win-0.1.96.iso -o $vmrc_root/isos/ || \
	{ echo "fetch failed. Exiting" ; exit 1 ; }

echo Fetching the UEFI firmware. Do update this!
fetch https://people.freebsd.org/~grehan/bhyve_uefi/BHYVE_UEFI_20151002.fd \
	-o $vmrc_root/bhyve_uefi/ || \
		{ echo "fetch failed. Exiting" ; exit 1 ; }

# Note that Windows vista requires virtio-win-0.1-94/virtio-win-0.1-94.iso

fetch https://people.freebsd.org/~grehan/bhyve_uefi/BHYVE_UEFI_CSM_20151002.fd \
	-o $vmrc_root/bhyve_uefi/ || \
		{ echo "fetch failed. Exiting" ; exit 1 ; }
