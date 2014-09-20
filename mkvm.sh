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
# Title: make VM script
# Version: v.0.7
#
# Script to provision FreeBSD Virtual Machines for use with vmrc
#
################################################################## USAGE
#
# Usage:
#
# Interactive: sh mkvm.sh
#
# Non-interactive: sh mkvm.sh <template name> <vm name> (sans id)

vm_mountpoint="" # Initialize to be safe

echo
echo Reading the /usr/local/etc/vm.conf config file
		. /usr/local/etc/vm.conf || \
		echo vm.conf config file failed to source. Exiting # ; exit 1

echo
echo Reading ./mkvm.sh.functions
		. ./mkvm.sh.functions || \
		echo ./mkvm.sh.functions failed to source. Exiting # ; exit 1

### STEP ONE : template to config file conversion and customization ###

echo
echo Verifying that $host_vmdir exists and generating a new VM ID
if [ ! $host_vmdir ]; then
		echo The VM directory was not sourced from /usr/local/etc/vm.conf
		exit
else
	echo
	echo Generating a new VM ID number
	vm_id=$( f_getnextid $host_vmdir )
	echo The resulting VM ID is $vm_id
fi

if [ $# -gt 0 ]; then # Non-interactive mode
	echo -------------------------------------------------------------
	echo -------------- Running in non-interactive mode --------------
	echo -------------------------------------------------------------
	echo The requested template is $1
	template=$1
	vm_name=$2$vm_id	
else # Interactive mode
	echo
	echo Listing VMs in $host_vmdir
	echo
	ls $host_vmdir
	echo
	echo Listing templates in $host_templates
	echo
	ls $host_templates
	echo

	while :
	do
	echo Enter a template to use:
	echo
	read template
# Better test?
	if [ "$template" = "" ]; then
		echo No template entered.
		echo 
	elif [ ! -f $host_templates/$template ]; then
			echo Template $host_templates/$template \
does not exist.
			echo
	else
		break
	fi
	done

	if [ ! -f $host_templates/$template ]; then
		echo Template $host_templates/$template does not exist.
		exit 1
	fi

	   	vm_name=vm$vm_id
		echo VM will be $vm_name by default.
		echo
	echo Enter a custom name without ID or leave blank to keep $vm_name
	echo
	read vm_new_name
	if [ ! "$vm_new_name" = "" ]; then
		vm_name=$vm_new_name$vm_id
	fi
fi

	echo
		echo The resulting VM will be named $vm_name

if [ ! -f ${host_templates}/$template ]; then
	   	echo Template $host_templates/$template does not exist.
		exit 1
fi

echo
echo Verifying if the VM already exists and making
echo $host_vmdir/$vm_name/mnt
if [ -f $host_vmdir/$vm_name ]; then
	echo $vm_name already exists. Exiting.
	exit 1
else
	echo Running mkdir -p $host_vmdir/$vm_name/mnt
	mkdir -p $host_vmdir/$vm_name/mnt
	if [ ! -d $host_vmdir/$vm_name/mnt ]; then
		echo $host_vmdir/$vm_name/mnt was not created. Exiting.
		exit 1
	fi
fi

echo
echo Running cp $host_templates/$template $host_vmdir/$vm_name/${vm_name}.conf
cp $host_templates/$template $host_vmdir/$vm_name/${vm_name}.conf

echo
echo Listing the contents of $host_vmdir/$vm_name/
ls $host_vmdir/$vm_name

# Ideally we do this after the malloc vm_device is added to the template 
if [ $# = 0 ]; then # Interactive mode
	echo
	echo Do you want to edit the configuration file in vi? y or n
	echo
	echo At this point you can set an existing VM boot device.
	echo
	read edit_in_vi
	case $edit_in_vi in
	y)
		vi $host_vmdir/$vm_name/${vm_name}.conf
	;;
	*)
		continue
	esac
fi

echo
echo Reading the $host_vmdir/$vm_name/${vm_name}.conf config file
		. $host_vmdir/$vm_name/${vm_name}.conf || \
		echo $vm_name config file failed to source. Exiting # ; exit 1

### STEP TWO : VM Storage Preparation ###

echo
echo Preparing VM storage

if [ ! "$install_method" = "rawimg" ]; then
case $vm_dev_type in
	device) # Use the device specified in the configuration file
		 return
	;;
	malloc) # Create the malloc device
		echo Creating the malloc device
		md_device=$( mdconfig -a -t malloc -s $vm_dev_size )
		echo Running mdconfig -lv
		mdconfig -lv
		sed -i '' -e "s/vm_device=\"\"/vm_device=\"${md_device}\"/" ${host_vmdir}/${vm_name}/${vm_name}.conf
	;;	
	img) # Create a disk image
		if [ ! -f $host_vmdir/$vm_name/${vm_name}.img ]; then
		echo
		echo Truncating $host_vmdir/$vm_name/${vm_name}.img
# BUG: Add a dd option because truncated files to not tar well
		truncate -s $vm_dev_size $host_vmdir/$vm_name/${vm_name}.img
		echo
		echo Listing the contents of $host_vmdir/$vm_name/
		ls -lh $host_vmdir/$vm_name/${vm_name}.img
			if [ ! -f $host_vmdir/$vm_name/${vm_name}.img ]; then
				echo Disk image failed to create. Exiting
				exit 1
			fi
		fi
	;;
	zvol) # Create a zvol
		if [ ! -e /dev/zvol/$host_zpool/$vm_name ]; then
			echo Creating zvol $host_zpool/$vm_name
	 	zfs create -V $vm_dev_size $vm_dev_flags $host_zpool/$vm_name
			zfs list | grep $vm_name
		else
			echo $host_zpool does not exist. Exiting
			echo Compare your zpool name to /usr/local/etc/vm.conf
			exit 1
		fi
	;;
	*) # Something went wrong
		echo vm_dev_type was not specified correctly. Exiting
		exit 1
		# FYI: Provisioning master_template will fail here if crawled
esac
fi # end install_method=rawimg test

# At this stage we should have a block device we can point the install at

# May need to set vm_device to it? or, any mdconfig is later...


### STEP THREE : Fetch raw image, ISO or distribution sets ###

# SIMPLIFICATION
# we know the payload name and could parse its ending for img|iso & xz|gz|other
# we could also parse a full url to a file but that would make for long config
# file entries and the parsing would have to be air-tight
# With that, we just case/if it for the known endings (though, may not be compressed)
# Do not expand the dist sets...
# Bother with the 8.4 dist set layout?
# pv?


echo
echo Fetching install media if not present in $host_distdir

# This blindly fetches everything in $site_payload, reagardless of install type
for distset in $site_payload; do
	if [ -f $host_distdir/$site_path$distset ]; then # File is present
		echo
		echo $host_distdir$site_path$distset already exists locally
	else
		mkdir -p $host_distdir$site_path		 # Harmless if present
		echo
		echo $host_distdir$site_path$distset is missing. Fetching
# Consider fetch -m mirror mode which verifies payload size BUT would not
# allow for offline use
		fetch -m $install_site$site_path$distset -o \
		$host_distdir/$site_path/
				if [ ! -f $host_distdir/$site_path$distset ]; then
			echo Distribution set did not fetch. Exiting
					exit 1
			fi
	fi
done

echo
echo Expanding or copying the payload as necessary
case $install_method in # Note that gunzip will take .xz, .gz, .bz2, .Z!
# CHECK IF EITHER IS COMPRESSED FIRST!!! MOST ISO'S ARE NOT!
# Note that gunzip will ignore endings that it does not recognize
	rawimg)
		case $payload_compressed in
		yes) echo ; echo Extracting $site_payload to ${vm_name}.img
		gunzip -c $host_distdir/$site_path/$site_payload > \
			$host_vmdir/$vm_name/${vm_name}.img	
		;;
		"") echo ; echo Copying $site_payload to ${vm_name}.img
		cp $host_distdir/$site_path/$site_payload \
			$host_vmdir/$vm_name/${vm_name}.img
		esac

		if [ ! -f $host_vmdir/$vm_name/${vm_name}.img ]; then
			echo
			echo ${vm_name}.img Failed to extract or copy. Exiting
			exit 1
		fi

		echo
		echo Checking if a tty change is requested
		if [ "$requires_tty" = "yes" ]; then
			echo
			echo Attaching ${vm_name}.img for tty change
			vm_mountpoint=$host_vmdir/$vm_name/mnt/
			vm_device=$( mdconfig -af $host_vmdir/$vm_name/${vm_name}.img ) ||
				{ echo ${vm_name}.img failed to attach. Exiting ; exit 1 ; }
			echo
			echo Running fsck on $vm_device$vm_dev_root
			fsck_ufs -y $vm_device$vm_dev_root

			echo
						echo Mounting $vm_device$vm_dev_root on $vm_mountpoint
						mount /dev/$vm_device$vm_dev_root $vm_mountpoint

				echo
				echo Verifying that VM mounted on its mount point
				( mount | grep -qw $vm_name/mnt ) || \
				{ echo $1 did not mount. Exiting ; exit 1 ; }
# BUG: Note that the md will remain

			echo
			echo Performing the tty change
				f_config_ttys_preflight $vm_name # mount grep vm_name
				f_config_ttys $vm_mountpoint
				f_config_ttys_debug $vm_mountpoint

				echo
				echo Unmounting $vm_mountpoint
				umount -f $vm_mountpoint

 			echo
				echo Detaching memory device $vm_device
				mdconfig -du $vm_device
		fi

				echo
				echo Directory structure ready and raw VM image fetched
				echo
				echo You can boot your VM with:
				echo service vm onestart $vm_name
		echo
		exit 1

	;;
	isoimg)
				case $payload_compressed in
				yes) echo ; echo Extracting $site_payload to ${vm_name}.iso
				gunzip -c $host_distdir/$site_path/$site_payload > \
						$host_vmdir/$vm_name/${vm_name}.iso
# BUG: Need a suffix-removal routine to link uncompressed ISOs. Or put in cfg
# Note: Who is shipping uncompressed ISOs?
				;;
				"") echo ; echo Linking $site_payload to ${vm_name}.iso
				ln -sf $host_distdir/$site_path/$site_payload \
						$host_vmdir/$vm_name/${vm_name}.iso
				esac

				if [ ! -f $host_vmdir/$vm_name/${vm_name}.iso ]; then
						echo ${vm_name}.iso Failed to extract or link. Exiting
						exit 1
				fi
		echo
		echo Directory structure ready and ISO fetched.
		echo
				echo Note that FreeBSD ISO installations may require
				echo this modication to /etc/ttys to boot properly:
				echo
				echo "ttyu0 \"/usr/libexec/getty 3wire.9600\" vt100 on secure"
				echo
		echo You can boot your VM with:
		echo service vm oneiso $vm_name
		echo
		exit 1

esac # ISO image installs are done at this point

# The remainder of this script is the FreeBSD manually installation

echo
echo Verifying that we are continuing with an artisnal FreeBSD provision

echo
echo Verifying that we are continuing with an artisnal FreeBSD provision
if [ "$vm_os_type" = "freebsd" ]; then
		case $install_method in
				distset) continue ;;
				obj) continue ;;
				iso) exit 1 ;;
				rawimg) exit 1 ;;
				*) echo How did you get this far? ; exit 1
		esac
fi

# Initialize vm_device variable

echo Continuing with FreeBSD artisnal provisioning
echo
echo Initializing the vm_device variable
case $vm_dev_type in
		device) # Use the device specified in the configuration file
			   return
		;;
		malloc) # Continue with the attached malloc device
		vm_device=$md_device
		;;
		img) # Attach the disk image
		vm_device=$( mdconfig -af $host_vmdir/$vm_name/${vm_name}.img ) ||
		{ echo ${vm_name}.img failed to attach. Exiting ; exit 1 ; }
	;;
	zvol) # Use the zvol that was created
				vm_device=zvol/$host_zpool/$vm_name
esac

echo
echo Prefixing $vm_device as /dev/$vm_device
vm_device=/dev/$vm_device

echo
echo The resulting VM device is $vm_device
echo
echo Verifying that $vm_device exists
if [ -e $vm_device ]; then
	echo Using $vm_device
else
	echo VM device $vm_device failed to initialize. Exiting
	exit 1
fi

echo
echo Initializing the vm_mountpoint variable as
echo $host_vmdir/$vm_name/mnt/
vm_mountpoint=$host_vmdir/$vm_name/mnt/

echo
echo Running f_${vm_dev_util}_${vm_dev_layout}_layout
f_${vm_dev_util}_${vm_dev_layout}_layout_preflight $vm_device
f_${vm_dev_util}_${vm_dev_layout}_layout $vm_device
f_${vm_dev_util}_${vm_dev_layout}_layout_debug $vm_device

# pointless here if a zvol move to function, need to test either way
echo
echo Running file on $host_vmdir/$vm_name/${vm_name}.img
file $host_vmdir/$vm_name/${vm_name}.img

echo
echo Running f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_boot
f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_boot_preflight $vm_device
f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_boot $vm_device
f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_boot_debug $vm_device

# again, pointless here
echo
echo Running file on $host_vmdir/$vm_name/${vm_name}.img
file $host_vmdir/$vm_name/${vm_name}.img
# Push test to function?

#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr_preflight $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_bootmgr_debug $vm_device
#file ${host_vmdir}/${vm_name}/${vm_name}.img

echo debug
ls ${vm_device}*
zfs list

echo
echo Formatting ZFS or UFS storage as appropriate
if [ "$vm_dev_fs" = "zfs" ]; then

	# Name the VM's pool in a non-conflicting way
	# One pool name for all VM's would be a dissaster when mounted on host
	vm_pool=${vm_name}pool

	echo
	echo Running f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_part
	f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_part_preflight $vm_device
	f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_part $vm_device
	f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_part_debug $vm_device

	echo
	echo Destroying the pool just in case
	zpool destroy $vm_pool

	case $vm_dev_layout in
		mbr)
			echo Destroying the gnop just in case
			gnop destroy -f ${vm_device}s1a.nop
		;;
		gpt)
			echo Destroying the gnop just in case
			gnop destroy -f ${vm_device}p2.nop
		;;
		*)
		echo Invalid VM device layout
		return
	esac

	# case layout=mbr - doesn't seem necessary
	#echo manually-adding-boot-code
	#dd if=/boot/zfsboot of=${vm_device}s1a skip=1 seek=1024

	echo
	echo Running f_${vm_dev_util}_${vm_dev_layout}_zpool
	f_${vm_dev_util}_${vm_dev_layout}_zpool_preflight $vm_device $vm_pool $vm_mountpoint
	f_${vm_dev_util}_${vm_dev_layout}_zpool $vm_device $vm_pool $vm_mountpoint
	f_${vm_dev_util}_${vm_dev_layout}_zpool_debug $vm_device $vm_pool $vm_mountpoint

	echo Running file on ${host_vmdir}/${vm_name}/${vm_name}.img
	file ${host_vmdir}/${vm_name}/${vm_name}.img
	# Push test to function?

	echo
	echo Running zpool import
	zpool import

	echo
	echo Running zpool import -o cachefile=none -R $vm_mountpoint $vm_pool
	zpool import -o cachefile=none -R $vm_mountpoint $vm_pool

	echo
	echo Running zpool list pipe grep $vm_pool
	zpool list | grep $vm_pool
	zfs list | grep $vm_pool
	echo Running mount pip grep $vm_pool
	mount | grep $vm_pool

else # UFS

# BUG: Missing MBR variant. Does this even belong here?
#	echo
#	echo Running f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_preflight $vm_device
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs $vm_device
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$vm_dev_fs"_newfs_debug $vm_device

	case $vm_dev_layout in
		mbr)
			echo
			echo Running f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_bootable
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_bootable_preflight $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_bootable $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_bootable_debug $vm_device
		;;
		gpt)
			echo
			echo Running f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_preflight $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${vm_dev_fs}_newfs_debug $vm_device
		;;
		*)
		echo Invalid VM device layout
		return
	esac

	echo
	echo Running ls $vm_device asterisk
	ls ${vm_device}*

echo
echo Mounting UFS-based storage if requested
# fsck is pointless as a test on a new device
# Note s1a/p2 - push or pull to/from config
	case $vm_dev_layout in
		mbr)
#			echo runningfsck
#			fsck_ufs -y ${vm_device}s1a
			echo Mounting ${vm_device}s1a on $vm_mountpoint
			mount ${vm_device}s1a $vm_mountpoint
		;;

		gpt)
#			echo runningfsck
#			fsck_ufs -y ${vm_device}p2
			echo Mounting ${vm_device}p2 on $vm_mountpoint
			mount ${vm_device}p2 $vm_mountpoint
		;;
		*)
		echo Invalid VM device layout
		return
	esac

	echo Running ls $vm_mountpoint
	ls $vm_mountpoint
# BUG: Could check for .snap on UFS filesystems
fi # end ZFS|UFS check

# Safety belt but we could proabably use more
echo
echo Running mountpoint checks to avoid extracting to root
if [ "$vm_mountpoint" = "" ]; then
	echo We do not want to install to root. Exiting
	exit 1
elif [ "$vm_mountpoint" = "/" ]; then
	echo We do not want to install to root. Exiting
	exit 1
fi

echo
echo Determining if install method is distribution set or src/obj
if [ "$install_method" = "distset" ]; then
	echo
	echo Running distribution set extraction loop
	for distset in $site_payload; do
		f_installset_preflight $host_distdir/$site_path/$distset  \
			$vm_mountpoint
		f_installset $host_distdir/$site_path/$distset $vm_mountpoint
	f_installset_debug $host_distdir/$site_path/$distset $vm_mountpoint
	done
elif [ "$install_method" = "obj" ]; then
	echo
	echo Verifying that sources and a built world and kernel are present
	if [ ! -f $obj_srcdir/Makefile ]; then
		echo Sources are not present in ${obj_srcdiri}. Exiting
		exit 1
	elif [ ! -d /usr/obj/usr ]; then
		echo Built world not present in /usr/obj/. Exiting
		exit 1
	elif [ ! -d /usr/obj/usr/src/sys ]; then
		echo Built kernel not present in /usr/obj/. Exiting
		exit 1
	fi

	echo
	echo Changing to the source directory for an obj installation
	cd $obj_srcdir
	echo
	echo Running make installworld to $vm_mountpoint
	make installworld DESTDIR=$vm_mountpoint
	echo
	echo Running make installkernel to $vm_mountpoint
	make installkernel DESTDIR=$vm_mountpoint
	echo
	echo Running make distribution to $vm_mountpoint
	make distribution DESTDIR=$vm_mountpoint
else
	echo
	echo Install method not set. Exiting
	exit 1
fi

echo
echo Running ls $vm_mountpoint
ls $vm_mountpoint

echo
echo Configuring loader
f_config_loader_conf_preflight $vm_mountpoint
f_config_loader_conf $vm_mountpoint
f_config_loader_conf_debug $vm_mountpoint

echo
echo Configuing fstab
if [ "$vm_dev_fs" = "zfs" ]; then
	f_config_zfs_fstab_preflight $vm_mountpoint
	f_config_zfs_fstab $vm_mountpoint
	f_config_zfs_fstab_debug $vm_mountpoint
else
	f_config_"$vm_dev_layout"_fstab_preflight $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab_debug $vm_mountpoint
fi

echo
echo Checking if a tty change is requested
if [ "$requires_tty" = "yes" ]; then
	f_config_ttys_preflight $vm_name
	f_config_ttys $vm_mountpoint
	f_config_ttys_debug $vm_mountpoint
fi

echo
echo Configuring time zone
f_config_tz_preflight $vm_mountpoint $vm_timezone
f_config_tz $vm_mountpoint $vm_timezone
f_config_tz_debug $vm_mountpoint $vm_timezone

echo
echo Configuring rc.conf
f_config_rc_conf_preflight $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf_debug $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw

echo
echo Configuring resolv.conf
if [ ! "$vm_ipv4" = "" ]; then
f_config_resolv_conf_preflight $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf_debug $vm_mountpoint $vm_searchdomain $vm_dns
fi

echo
echo Enabling ssh root access
f_config_sshd_root_preflight $vm_mountpoint
f_config_sshd_root $vm_mountpoint
f_config_sshd_root_debug $vm_mountpoint

echo
echo Setting root password
f_set_password_preflight $vm_password $vm_mountpoint
f_set_password $vm_password $vm_mountpoint
f_set_password_debug $vm_password $vm_mountpoint


### LAST CHANCE TO MODIFIY THE VM FILESYSTEM ###
### Modify or copy in files as appropriate ###

echo
echo Exporting or unmounting
if [ "$vm_dev_fs" = "zfs" ]; then
	echo
	echo Exporting pool $vm_pool
	zpool export $vm_pool
else
	echo
	echo Unmounting $vm_mountpoint
	umount -f $vm_mountpoint
fi

if [ "$vm_dev_type" = "malloc" ]; then
	echo
	echo Leaving memory device $md_device attached for use
else
	echo
	echo Detaching memory device $vm_device
	mdconfig -du $vm_device
fi

echo
echo You can boot your VM with:
echo service vm onestart $vm_name
echo
