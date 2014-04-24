#!/bin/sh
# Version: v.0.6

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

# This script downloads and  prepares a recent FreeNAS bootable "img" image
# for use with bhyve.

# USAGE
#
# sh t_freenas-fetch.sh
#
# CAUTION: This will forcibly unmount and use /mnt

# TO DO
# Read in vm.conf, use proper variables

# Read the host's vm.conf
. /usr/local/etc/vm.conf

# March 2014 Scheme:
#http://download.freenas.org/9.2.1.3/RELEASE/x64/FreeNAS-9.2.1.3-RELEASE-x64.iso 
echo
echo "Recent releases: 8.3.2 9.2.1.5"
echo
echo "Enter a release to fetch:"
echo
read release

echo "Existing VMs:"
ls /usr/local/vmrc/vm/
echo
echo "Enter a new VM name with ID: i.e. vm0"
echo
read vm_name 

IMGSITE="http://download.freenas.org/${release}/RELEASE/x64/"
IMG="FreeNAS-${release}-RELEASE-x64.img.xz"
EXPANDED=${IMG%.xz}
MNT=/mnt/

if [ ! -d $host_distdir ]; then
	mkdir -p $host_distdir
fi

if [ ! -f $host_distdir/$IMG ]; then
	echo "Fetching $IMGSITE$IMG"
	fetch $IMGSITE$IMG -o $host_distdir
fi

if [ ! -f ${host_distdir}/$IMG ]; then
	echo "$IMG failed to fetch. Exiting."
	exit
fi

if [ ! -f ${host_distdir}/$EXPANDED ]; then
	echo "Expanding $IMG"
	unxz --keep ${host_distdir}/$IMG
fi

mkdir -p ${host_vmdir}/${vm_name}/mnt

echo "Copying ${host_distdir}/$EXPANDED to $vm_name"
cp ${host_distdir}/$EXPANDED ${host_vmdir}/${vm_name}/${vm_name}.img

if [ ! -d $MNT ]; then
	echo "$MNT is missing. Creating."
	mkdir -p $MNT
fi

echo
echo "Force unmounting $MNT"
echo

umount -f $MNT

echo "Preparing disk image ${vm_name}.img"
echo
MD=$( mdconfig -af ${host_vmdir}/${vm_name}/${vm_name}.img )
echo "md device is $MD"
echo
echo "Running mdconfig -lv"
echo
mdconfig -lv

if [ ! -e /dev/${MD}s1a ]; then
        echo "Image does not appear to be attached. Exiting."
        exit
fi

echo
echo "Running fsck_ufs on /dev/${MD}s1a"
echo
fsck_ufs -y /dev/${MD}s1a
echo
echo "Mounting /dev/${MD}s1a on $MNT"
echo
mount /dev/${MD}s1a $MNT

echo "Running mount"
echo
mount | grep $MD

echo "Backing up the original /etc/ttys"
echo "Running cp $MNT/etc/ttys $MNT/etc/ttys.orig"
echo
cp $MNT/etc/ttys $MNT/etc/ttys.orig

echo "Enabling the required console"
echo

cat >> $MNT/etc/ttys << EOF
console "/usr/libexec/getty freenas"   vt100   on   secure
EOF

echo "Running tail $MNT/etc/ttys"
echo
tail $MNT/etc/ttys

if [ "$release" = "8.3.2" ]; then
	echo "Copying in 8.x VirtIO kernel modules"
	cp ./virtio83R/* ${MNT}/boot/kernel/
	echo "Listing the kernel modules"
	ls ${MNT}/boot/kernel/

	cat >> ${MNT}/boot/loader.conf << EOF
virtio_load="YES"
virtio_pci_load="YES"
virtio_blk_load="YES"
if_vtnet_load="YES"
EOF

	echo "Showing the loader.conf"
	cat ${MNT}/boot/loader.conf
echo
echo "WARNING: 8.3.2 does not appear to like the if_vtnet driver"
fi

echo
echo "Unmounting $MNT"
umount $MNT
echo

echo "Running mount"
mount | grep $MD
echo

echo "Destroying $MD"
mdconfig -du $MD
echo

echo "Running mdconfig -lv"
mdconfig -lv
echo

echo "Copying in the configuration template"
cp ${host_templates}/t_freenas ${host_vmdir}/${vm_name}/${vm_name}.conf
echo

echo "Listing the contents of ${host_vmdir}/${vm_name}/"
ls ${host_vmdir}/${vm_name}/

