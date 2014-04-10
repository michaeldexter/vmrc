#!/bin/sh

# Version v.0.5

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

# Script to provision FreeBSD Virtual Machines for use with vmrc

# Usage:
#
# Interactive: sh mkvm.sh
#
# Non-interactive: sh mkvm.sh <template name> <vm name> (sans id)

vm_mountpoint="" # Initialize to be safe

. /usr/local/etc/vm.conf
. ./mkvm.sh.functions

if [ ! $host_vmdir ]; then
        echo "The VM directory was not sourced from /usr/local/etc/vm.conf"
        exit
else
	vm_id=$( f_getnextid $host_vmdir )
fi

if [ $# -gt 0 ]; then # Non-interactive mode
	template=$1
	vm_name=$2$vm_id	
else # Interactive mode
	echo "Listing VMs in $host_vmdir"
	echo
	ls $host_vmdir
	echo
	echo "Listing templates in $host_templates"
	echo
	ls $host_templates
	echo

	while :
	do
	echo "Enter a template to use:"
	echo
	read template
# Better test?
	if [ "$template" = "" ]; then
		echo "No template entered."
		echo 
	elif [ ! -f ${host_templates}/$template ]; then
			echo "Template ${host_templates}/$template \
does not exist."
			echo
	else
		break
	fi
	done

	if [ ! -f ${host_templates}/$template ]; then
		echo "Template ${host_templates}/$template does not exist."
		exit
	fi

       	vm_name=vm$vm_id
        echo "VM will be $vm_name by default."
        echo
	echo "Enter a custom name without ID or leave blank to keep $vm_name"
	echo
	read vm_new_name
	if [ ! "$vm_new_name" = "" ]; then
		vm_name=$vm_new_name$vm_id
	fi
fi

        echo "The VM is named $vm_name"

echo "debug: echoing template name"
echo $template

if [ ! -f ${host_templates}/$template ]; then
       	echo "Template ${host_templates}/$template does not exist."
        exit
fi

if [ -f ${host_vmdir}/${vm_name} ]; then
	echo "$vm_name already exists. Something when wrong. Exiting."
	exit
else
	mkdir -p ${host_vmdir}/${vm_name}/mnt
	if [ ! -d ${host_vmdir}/${vm_name}/mnt ]; then
		echo "${host_vmdir}/${vm_name}/mnt was not created. Exiting."
		exit
	fi
fi

echo "Running: cp ${host_templates}/$template ${host_vmdir}/${vm_name}/${vm_name}.conf"
cp ${host_templates}/$template ${host_vmdir}/${vm_name}/${vm_name}.conf

echo "Listing the contents of ${host_vmdir}/${vm_name}"
ls ${host_vmdir}/${vm_name}

# Ideally we do this after the malloc vm_device is set
if [ $# = 0 ]; then # Interactive mode
	echo
	echo "Do you want to edit the configuration file in vi? y or n"
	echo "At this point you can set an existing VM boot device."
	echo
	read edit_in_vi
	case "$edit_in_vi" in
	y)
		vi ${host_vmdir}/${vm_name}/${vm_name}.conf
	;;
	n)
		continue
	;;
	*)
		continue
	;;
	esac
fi

# Hmm, create VM-specific iSCSI targets? (triggered from here)

echo "Sourcing the configuration file ${host_vmdir}/${vm_name}/${vm_name}.conf"
. ${host_vmdir}/${vm_name}/${vm_name}.conf

echo "Overriding vm_pool with $vm_name"
vm_pool=$vm_name

echo "Checking vm_dev_util from the config file to see if sourced correctly:"
if [ "$vm_os_type" = "" ]; then
	echo "The configuration file was not sourced correctly. Exiting."
	exit
else
	echo "Configuration file read."
fi

echo "The mount point will be ${host_vmdir}/${vm_name}/mnt/"
vm_mountpoint=${host_vmdir}/${vm_name}/mnt/

#echo JustInCase-export-pool
# The POOL could be mounted on the mount point!
# export $vm_pool
#echo JustInCase-destroy-memory-dev
#mdconfig -du $vm_device
#echo JustInCase-ls-dev
#ls ${vm_device}*
#echo JustInCase-remove-${host_vmdir}/vm${nextid}/vm${nextid}.img
#rm ${host_vmdir}/vm${nextid}/vm${nextid}.img

echo "Preparing storage..."

if [ ! $vm_device = "" ]; then
	continue
elif [ $vm_dev_type = "malloc" ]; then
	md_device=$( mdconfig -a -t malloc -s $vm_dev_size )
	sed -i '' -e "s/vm_device=\"\"/vm_device=\"${md_device}\"/" ${host_vmdir}/${vm_name}/${vm_name}.conf
	vm_device="/dev/$md_device"
	mdconfig -lv
	echo "Looking at ${host_vmdir}/${vm_name}/${vm_name}.conf"
	cat ${host_vmdir}/${vm_name}/${vm_name}.conf | grep vm_device
else
	truncate -s $vm_dev_size ${host_vmdir}/${vm_name}/${vm_name}.img
	md_device=$( mdconfig -af "${host_vmdir}/${vm_name}/${vm_name}.img" )
	vm_device="/dev/$md_device"
	mdconfig -lv
fi

echo "Running file ${host_vmdir}/vm${nextid}/vm${nextid}.img"
file ${host_vmdir}/${vm_name}/${vm_name}.img

echo "Running: f_"$vm_dev_util"_"$vm_dev_layout"_layout_preflight $vm_device"
f_"$vm_dev_util"_"$vm_dev_layout"_layout_preflight $vm_device
f_"$vm_dev_util"_"$vm_dev_layout"_layout $vm_device
f_"$vm_dev_util"_"$vm_dev_layout"_layout_debug $vm_device
file ${host_vmdir}/${vm_name}/${vm_name}.img

f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_boot_preflight $vm_device
f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_boot $vm_device
f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_boot_debug $vm_device
file ${host_vmdir}/${vm_name}/${vm_name}.img

#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr_preflight $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr_debug $vm_device
#file ${host_vmdir}/${vm_name}/${vm_name}.img

if [ $vm_dev_fs = "zfs" ]; then
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_part_preflight $vm_device
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_part $vm_device
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_part_debug $vm_device


	echo JustInCase-destroy-pool
	zpool destroy $vm_pool

	case "$vm_dev_layout" in
		mbr)
			echo JustInCase-destroy-gnop
			gnop destroy -f ${vm_device}s1a.nop
		;;
		gpt)
			echo JustInCase-destroy-gnop
			gnop destroy -f ${vm_device}p2.nop
		;;
		*)
		info "Invalid VM device layout"
		return
	esac

	# case layout=mbr - doesn't seem necessary
	#echo manually-adding-boot-code
	#dd if=/boot/zfsboot of=${vm_device}s1a skip=1 seek=1024


	f_"$vm_dev_util"_"$vm_dev_layout"_zpool_preflight $vm_device $vm_pool $vm_mountpoint
	f_"$vm_dev_util"_"$vm_dev_layout"_zpool $vm_device $vm_pool $vm_mountpoint
	f_"$vm_dev_util"_"$vm_dev_layout"_zpool_debug $vm_device $vm_pool $vm_mountpoint
	file ${host_vmdir}/${vm_name}/${vm_name}.img

	echo zpool-import
	zpool import

	echo zpool-import-pool
	zpool import -o cachefile=none -R $vm_mountpoint $vm_pool

	echo zpool-zfs-list-mount
	zpool list | grep $vm_pool
	zfs list | grep $vm_pool
	mount | grep $vm_pool
else
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_preflight $vm_device
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs $vm_device
	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_debug $vm_device

	case "$vm_dev_layout" in
		mbr)
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_bootable_preflight $vm_device
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_bootable $vm_device
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_bootable_debug $vm_device
		;;
		gpt)
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_preflight $vm_device
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs $vm_device
			f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_debug $vm_device
		;;
		*)
		info "Invalid VM device layout"
		return
	esac

	ls ${vm_device}*

# fsck is pointless as a test on a new device AND his sometimes
# hard-crashing PC-BSD
	case "$vm_dev_layout" in
		mbr)
#			echo runningfsck
#			fsck_ufs -y ${vm_device}s1a
			echo runningMount
			mount ${vm_device}s1a $vm_mountpoint
		;;
		gpt)
#			echo runningfsck
#			fsck_ufs -y ${vm_device}p2
			echo runningMount
			mount ${vm_device}p2 $vm_mountpoint
		;;
		*)
		info "Invalid VM device layout"
		return
	esac

	echo running-ls
	ls $vm_mountpoint
fi


if [ ! -d ${host_distdir}/${vm_os_ver} ]; then # Missing
	echo "${host_distdir}/${vm_os_ver} is missing. Creating it."
	mkdir -p ${host_distdir}/${vm_os_ver}
fi

# PUSH THESE TO THE FUNCTIONS AS APPROPRIATE ONCE WORKING

# todo: if vm_os_type=freebsd8... fetch segments and re-package

for distset in $vm_distsets; do
if [ ! -f ${host_distdir}/${vm_os_ver}/$distset ]; then # Missing
	echo "${host_distdir}/${vm_os_ver}/$distset is missing. Fetching."

	fetch ${dist_site}/${distset} -o ${host_distdir}/${vm_os_ver}/
fi

if [ ! -e ${host_distdir}/${vm_os_ver}/$distset ]; then # Still missing
	echo "$distset did not fetch. Exiting."
	exit
fi

	f_installset_preflight ${host_distdir}/${vm_os_ver}/$distset \
		$vm_mountpoint
	f_installset ${host_distdir}/${vm_os_ver}/$distset $vm_mountpoint
	f_installset_debug ${host_distdir}/${vm_os_ver}/$distset $vm_mountpoint
done

echo "Running ls $vm_mountpoint"
ls $vm_mountpoint

f_config_loader_conf_preflight $vm_mountpoint
f_config_loader_conf $vm_mountpoint
f_config_loader_conf_debug $vm_mountpoint

if [ $vm_dev_fs = "zfs" ]; then
	f_config_zfs_fstab_preflight $vm_mountpoint
	f_config_zfs_fstab $vm_mountpoint
	f_config_zfs_fstab_debug $vm_mountpoint
else
	f_config_"$vm_dev_layout"_fstab_preflight $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab_debug $vm_mountpoint
fi

f_config_ttys_preflight $vm_mountpoint
f_config_ttys $vm_mountpoint
f_config_ttys_debug $vm_mountpoint

f_config_tz_preflight $vm_mountpoint $vm_timezone
f_config_tz $vm_mountpoint $vm_timezone
f_config_tz_debug $vm_mountpoint $vm_timezone

f_config_rc_conf_preflight $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf_debug $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw

f_config_resolv_conf_preflight $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf_debug $vm_mountpoint $vm_searchdomain $vm_dns

f_config_sshd_root_preflight $vm_mountpoint
f_config_sshd_root $vm_mountpoint
f_config_sshd_root_debug $vm_mountpoint

f_set_password_preflight $vm_password $vm_mountpoint
f_set_password $vm_password $vm_mountpoint
f_set_password_debug $vm_password $vm_mountpoint


#ls ${vm_device}*

### LAST CHANCE TO MODIFIY THE VM FILESYSTEM ###
### Modify or copy in files as appropriate ###



if [ $vm_dev_fs = "zfs" ]; then
	echo exporting-pool
	zpool export $vm_pool
else
	echo unmounting-vm-mount-point
	umount -f $vm_mountpoint
fi

if [ $vm_dev_type = "malloc" ]; then
	echo "Leaving malloc device $vm_device attached for use"
else
	echo detaching-md
	mdconfig -du $vm_device
fi

echo
echo "$vm_name Provisioned with IP address $vm_ipv4"
echo

if [ $# = 0 ]; then # Interactive mode
        echo
        echo "Do you want to start it? y or n"
        echo
        read startvm
        case "$startvm" in
        y)
                service vm start $vm_name
        ;;
        n)
		exit
        ;;
        *)
		exit 
        ;;
        esac
fi

# Optional rename syntax
#	if [ ! vm_new_name = "" ]; then
#		mv ${host_vmdir}/${vm_name} ${host_vmdir}/${vm_new_name}
#		mv ${host_vmdir}/${vm_new_name}/${vm_name}.conf \
#			${host_vmdir}/${vm_new_name}/${vm_new_name}.conf
#		if [ -f ${host_vmdir}/${vm_new_name}/${vm_name}.img ]; then
#			mv ${host_vmdir}/${vm_new_name}/${vm_name}.img \
#				${host_vmdir}/${vm_new_name}/${vm_new_name}.img
#		fi
#	fi



