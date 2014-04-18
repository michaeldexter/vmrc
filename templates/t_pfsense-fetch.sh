#!/bin/sh
# Version: v.0.5

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

# This script downloads and prepares a recent pfSense 2GB/serial bootable
# "img" image for use with bhyve.

# USAGE
#
# sh t_pfsense-fetch.sh
#
# CAUTION: This will forcibly unmount and use /mnt
# Check for /mnt afterwards on PC-BSD to see if the automounter removed it

# TO DO
# Perhaps configure the second partition in case people boot to it.

# pfSense Steps
# /boot/loader.conf: change comconsole to userboot (does not show loader)
# /boot/loader.conf.local (or loader.conf): load VirtIO modules
# Serial image: No tty change
# VGA image: Add the proper tty
# Optionally, one can load all VirtIO modules at the loader prompt

# Note: vtnet0 is not showing up for the "a" autodetection

# Read the host's vm.conf
. /usr/local/etc/vm.conf

# April 2014 Scheme:
#http://files.nyi.pfsense.org/mirror/downloads/pfSense-2.1.1-RELEASE-2g-amd64-nanobsd.img.gz

echo
echo "Recent releases: 2.1, 2.1.2"
echo
echo "Enter a release to fetch:"
echo
read release

echo "Existing VMs: (This script will overwrite an existing one if specified.)"
ls /usr/local/vmrc/vm/
echo
echo "Enter a new VM name with ID: i.e. vm0"
echo
read vm_name 

IMGSITE="http://files.nyi.pfsense.org/mirror/downloads/"
IMG="pfSense-${release}-RELEASE-2g-amd64-nanobsd.img.gz"
EXPANDED=${IMG%.gz}
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
	gunzip  ${host_distdir}/$IMG
fi

mkdir -p ${host_vmdir}/${vm_name}/mnt

echo "Copying ${host_distdir}/$EXPANDED to $vm_name"
cp ${host_distdir}/$EXPANDED ${host_vmdir}/${vm_name}/${vm_name}.img

if [ ! -d $MNT ]; then
	echo "$MNT is missing. Creating."
	mkdir -p $MNT
fi

echo "Force unmounting $MNT"
echo

umount -f $MNT

# FYI

# gpart show md0
#=>      1  3886658  md0  MBR  (1.9G)
#        1       62       - free -  (31K)
#       63  1890945    1  freebsd  [active]  (923M)
#  1891008       63       - free -  (32K)
#  1891071  1890945    2  freebsd  (923M)
#  3782016   102816    3  freebsd  (50M)
#  3884832     1827       - free -  (914K)

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

echo
echo "Running mount"
echo
mount | grep $MD

# Enable the following for the pfSense VGA image
# In theory this is not needed with the serial image
#echo "Backing up the original /etc/ttys"
#echo "Running cp $MNT/etc/ttys $MNT/etc/ttys.orig"
#echo
#cp $MNT/etc/ttys $MNT/etc/ttys.orig
#echo "Enabling the required console"
#echo
#cat >> $MNT/etc/ttys << EOF
#console "/usr/libexec/getty freenas"   vt100   on   secure
#EOF
#echo "Running tail $MNT/etc/ttys"
#echo
#tail $MNT/etc/ttys

echo "Backing up the original /boot/loader.conf"
echo "Running cp $MNT/etc/ttys $MNT/boot/loader.conf.orig"
echo
cp $MNT/boot/loader.conf $MNT/boot/loader.conf.orig

sed -i '' -e "s/comconsole/"\"userboot\"/ $MNT/boot/loader.conf

echo "Showing the /boot/loader.conf"
echo
cat ${MNT}/boot/loader.conf

cat >> ${MNT}/boot/loader.conf.local << EOF
virtio_load="YES"
virtio_pci_load="YES"
virtio_blk_load="YES"
if_vtnet_load="YES"
EOF

echo
echo "Showing the loader.conf.local"
echo
cat ${MNT}/boot/loader.conf.local

echo
echo "Unmounting $MNT"
echo
umount $MNT

echo "Running mount"
echo
mount | grep $MD

echo "Destroying $MD"
mdconfig -du $MD

echo "Running mdconfig -lv"
mdconfig -lv

echo "Copying in the configuration template"
cp ${host_templates}/t_pfsense ${host_vmdir}/${vm_name}/${vm_name}.conf

echo "Listing the contents of ${host_vmdir}/${vm_name}/"
ls ${host_vmdir}/${vm_name}/

