#!/bin/sh
# 
################################################################ LICENSE
#
# Copyright (c) 2012-2016 Michael Dexter <editor@callfortesting.org>
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
# Version: v.0.9.7
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
#
########################################################################

### PREFLIGHT CHECKS ###

# suid=$( id -u ) ; [ "$suid" = "0" ] || \
[ `id -u` -ne 0 ] && \
	{ echo Must be excuted with root privileges. Exiting ; exit 1 ; }

[ -z ${2##*[!0-9]} ] || \
{ echo The requested VM name $2 cannot end in a number. Exiting ; exit 1 ; }

[ -f /usr/local/etc/vmrc.conf ] || \
	{ echo /usr/local/etc/vmrc.conf does not exist. Exiting ; exit 1 ; }
[ -r /usr/local/etc/vmrc.conf ] || \
	{ echo /usr/local/etc/vmrc.conf is not readable. Exiting ; exit 1 ; }
/bin/sh -n /usr/local/etc/vmrc.conf >/dev/null 2>&1 || \
	{ echo /usr/local/etc/vmrc.conf failed to parse. Exiting ; exit 1 ; }
echo ; echo Reading /usr/local/etc/vmrc.conf
. /usr/local/etc/vmrc.conf >/dev/null 2>&1 || \
	{ echo vmrc.conf failed to source. Exiting ; exit 1 ; }

# Verify that the paths are set

[ $host_templates ] || \
	{ echo host_templates is not set in vmrc.conf. Exiting ; exit 1 ; }
[ $host_distdir ] || \
	{ echo host_distdir is not set in vmrc.conf. Exiting ; exit 1 ; }
[ $host_vmdir ] || \
	{ echo host_vmdir is not set in vmrc.conf. Exiting ; exit 1 ; }

# Verify that the paths begin and end with "/"

[ "${host_templates%${host_templates#?}}" = "/" ] ||
	{ echo host_templates must begin with \"/\". Exiting ; exit 1 ; }
[ "${host_templates#${host_templates%?}}" = "/" ] ||
	{ echo host_templates must end with \"/\". Exiting ; exit 1 ; }
[ "${host_distdir%${host_distdir#?}}" = "/" ] ||
	{ echo host_distdir must begin with \"/\". Exiting ; exit 1 ; }
[ "${host_distdir#${host_distdir%?}}" = "/" ] ||
	{ echo host_distdir must end with \"/\". Exiting ; exit 1 ; }
[ "${host_vmdir%${host_vmdir#?}}" = "/" ] ||
	{ echo host_vmdir must begin with \"/\". Exiting ; exit 1 ; }
[ "${host_vmdir#${host_vmdir%?}}" = "/" ] ||
	{ echo host_vmdir must end with \"/\". Exiting ; exit 1 ; }

echo echo Checking for required functions library
[ -f ./mkvm.sh.functions ] || \
	{ echo ./mkvm.sh.functions does not exist. Exiting ; exit 1 ; }
echo Checking if required functions library is readable
[ -r ./vmrc.conf ] || \
	{ echo ./mkvm.sh.functions is not readable. Exiting ; exit 1 ; }
echo Running sh n on required functions library
/bin/sh -n ./mkvm.sh.functions >/dev/null 2>&1 || \
	{ echo ./mkvm.sh.functions failed to parse. Exiting ; exit 1 ; }
echo Reading ./mkvm.sh.functions
. ./mkvm.sh.functions >/dev/null 2>&1 || \
	{ echo ./mkvm.sh.functions failed to source. Exiting ; exit 1 ; }


### FUNCTIONS ###

# NB! Is this triple digit safe?
f_getnextid() ## $1 host_vmdir from /usr/local/etc/vmrc.conf
{
	local nextid=0 # Initialize to 0
	local conflict=""

	if [ $( ls $1 | wc -l ) = 0 ]; then # None exist. A better test?
# Note -d check in vm_start
		echo $nextid # Use the initialized zero
		exit 0
	else
		while :; do # Loop until satisfied - risky?
			for vm_found in ${1}/* ; do # Full path name
				vm_foundname="${vm_found##*/}" # Strip path
				vm_foundid="${vm_foundname##*[!0-9]}"
				if [ "$vm_foundid" = "$nextid" ]; then
					conflict="yes"
				fi
			done # Pass completed

			if [ "$conflict" = "yes" ]; then
				nextid=$(($nextid+1))
				conflict="" # Reset "conflict" !
			else
				echo $nextid
				exit 0
			fi
		done
	fi
} # End f_getnextid

f_filetype() # A smarter file(1) that is briefer than brief mode
{
case $( file -bi $1 ) in
	"application/x-bzip2; charset=binary") echo .bz2
	;;
	"application/x-compress; charset=binary") echo .Z
	;;
	"application/x-gzip; charset=binary") echo .gz
	;;
	"application/x-xz; charset=binary") echo .xz
	;;
	"application/x-zip; charset=binary") echo .zip
	;;
	*) echo "Uncompressed" # This might want to be a return value
esac
# FYI images are application/octet-stream; charset=binary
} # End f_filetype

f_dehumanize() # $1 # Human readable storage i.e. 1GB in, bytes out
{
	disk_size_number=${1%[!0-9]}
	disk_size_unit=${1##*[0-9]}

# NB! Do we want more clever ways of saying "kilobyte"? KiB?
case $disk_size_unit in
	b|B)
	disk_size_bytes=$disk_size_number
	;;
	k|K|KB)
	disk_size_bytes=$(( $disk_size_number * 1024 ))
	;;
	m|M|MB)
	disk_size_bytes=$(( $disk_size_number * 1024 * 1024 ))
	;;
	g|G|GB)
	disk_size_bytes=$(( $disk_size_number * 1024 * 1024 * 1024 ))
	;;
	t|T|TB)
	disk_size_bytes=$(( $disk_size_number * 1024 * 1024 * 1024 * 1024 ))
	;;
esac

echo $disk_size_bytes
} # End f_dehumanize

del_vm() # Note that this operates on the hard-coded $vm_name
{
echo ; echo Deleting $vm_name
[ $( zfs get -pH name $host_zpool$host_vmdir$vm_name > /dev/null 2>&1 ) ] && \
{ echo Destroying VM with zfs destroy -f -r $host_zpool$host_vmdir$vm_name ; \
		zfs destroy -f -r $host_zpool$host_vmdir$vm_name ; }

	echo Running rm -rf $host_vmdir/$vm_name
	umount -f $host_vmdir/$vm_name/mnt > /dev/null 2>&1
	rm -rf $host_vmdir/$vm_name
}


### STEP ONE : Building VM directory based on the specified template ###

# Check that $host_vmdir is set
[ -z $host_vmdir ] && \
	{ echo host_vmdir is not set from vmrc.conf. Exiting ; exit 1 ; }

[ -w $host_vmdir ] || \
	{ echo host_vmdir is not writable. Exiting ; exit 1 ; }

echo ; echo Generating a new VM ID number
vm_id=$( f_getnextid $host_vmdir )
echo The resulting VM ID is $vm_id

if [ "$#" -gt 0 ]; then # Non-interactive mode
	echo -------------------------------------------------------------
	echo -------------- Running in non-interactive mode --------------
	echo -------------------------------------------------------------
	echo The requested template is\: $1
	echo The requested VM name is\: $2
	echo

# Verify if two arguments are passed in
[ "$#" = "2" ] || \
{ echo Either VM template or name were not specified. Exiting ; exit 1 ; }

[ -z ${2##*[!0-9]} ] || \
{ echo The VM name $2 cannot end in a number. Exiting ; exit 1 ; }

	template=$1
	vm_name=$2$vm_id	

else # Enter interactive mode

	echo ; echo Listing VMs in $host_vmdir
	echo ; ls $host_vmdir
	echo ; echo Listing templates in $host_templates
	echo ; ls $host_templates ; echo

	echo ; echo Enter a template to use: ; echo

	read template
	[ $template ] || \
		{ echo No template entered. Exiting ; exit 1 ; }
	[ -r "$host_templates/$template" ] || \
		{ echo Template canot be read. Exiting ; exit 1 ; }

		vm_name=vm$vm_id
		echo VM will be $vm_name by default.
		echo
	echo Enter a custom name without ID or leave blank to keep $vm_name
	echo
	read vm_new_name
	if [ ! "$vm_new_name" = "" ]; then
		vm_name=$vm_new_name$vm_id
	fi
fi # End non-interactive/interactive test

[ -f $host_vmdir/$vm_name ] && \
	{ echo $host_vmdir/$vm_name already exists. Exiting ; exit 1 ; }
[ -r $host_templates/$template ] || \
	{ echo $host_templates/$template not found. Exiting ; exit 1 ; }

echo
echo The resulting VM will be named $vm_name and use $host_templates/$template

# Verify if a host zpool is specified and verify if it exists, if it does,
# use datasets rather than directories in host_vmdir

echo ; echo Verifying if a zpool and datasets are requested
if [ ! "$host_zpool" ]; then

	echo ; echo Creating $host_vmdir/$vm_name directory
	mkdir -p $host_vmdir/$vm_name

else
	echo ; echo Verifying if zpool $host_zpool exists
	zpool get -pH name $host_zpool > /dev/null 2>&1
		[ $? -gt 0 ] && \
	{ echo Requested zpool $host_zpool does not exist. Exiting ; exit 1 ; }

	if [ $( grep FreeNAS /etc/version > /dev/null 2>&1 ) ]; then
		echo Appears to be a FreeNAS host
		host_vmdir_mp=${host_vmdir#/mnt} # mp = mount point
# Explain this mapping - Remove "/mnt" from the pool name?
	else
		host_vmdir_mp=$host_vmdir
	fi

	echo ; echo Creating $host_vmdir$vm_name dataset

# See if the dataset does not exist
if [ ! $( zfs get -pH name $host_zpool$host_vmdir$vm_name > /dev/null 2>&1 ) ]; then
zfs create -p -o mountpoint=$host_vmdir_mp$vm_name $host_zpool$host_vmdir$vm_name

[ -d $host_vmdir_mp$vm_name ] || \
	{ echo The $host_vmdir_mp$vm_name dataset failed to create. \
	Trying a directory instead ; \
	mkdir -p $host_vmdir_mp$vm_name ; }

[ -d $host_vmdir_mp$vm_name ] || \
	{ echo $host_vmdir$vm_name_mp failed to create. Exiting ; exit 1 ; }

fi # End dataset test
fi # End pool test

[ -w $host_vmdir/$vm_name ] || \
	{ echo $host_vmdir$vm_name failed to create. Exiting ; exit 1 ; }
# NB! Nothing to delete at this point, right?

# NB! Should this use vm_name_mp? Test on FreeNAS!

# ~/mnt is only used for temporary mounts. No need for a dataset
echo ; echo Creating $host_vmdir$vm_name/mnt directory
mkdir -p $host_vmdir$vm_name/mnt

[ -w $host_vmdir$vm_name/mnt ] || \
{ echo $host_vmdir$vm_name/mnt was not created. Exiting ; del_vm ; exit 1 ; }

echo ; echo Running cp $host_templates/$template $host_vmdir$vm_name/vm.conf
cp $host_templates/$template $host_vmdir$vm_name/vm.conf

[ -r $host_vmdir$vm_name/vm.conf ] || \
{ echo $host_vmdir$vm_name/vm.conf failed to copy. Exiting ; del_vm ; exit 1 ; }

# If in interactive mode, offer a chance to edit the file in place

if [ $# = 0 ]; then # Again verify if in interactive mode
	echo ; echo Do you want to edit the configuration file in vi?
echo ; echo "(for example to set an existing VM hardware boot device)"
	echo ; echo Y or N ; echo
	read edit_in_vi
	case $edit_in_vi in
	y|Y|yes|Yes|YES)
		vi $host_vmdir$vm_name/vm.conf
	;;
	*)
		continue
	esac
fi

echo ; echo Reading the $host_vmdir$vm_name/vm.conf config file
sh -n $host_vmdir$vm_name/vm.conf >/dev/null 2>&1 || \
{ echo $vm_name config file failed parse. Deleting VM ; del_vm ; exit 1 ; }

. $host_vmdir$vm_name/vm.conf || \
{ echo $vm_name config file failed to source. Deleting VM ; del_vm ; exit 1 ; }

# Aborting early on these because we won't get far without them

echo
echo Validating key variables in the $host_vmdir$vm_name/vm.conf config file

[ -z $install_site ] && \
{ echo install_site is not set. Deleting VM ; del_vm ; exit 1 ; }

# One COULD have a file:// setting and the payloads copied in?
#[ -z $site_path ] && \
#{ echo site path is not set. Deleting VM ; del_vm ; exit 1 ; }

[ -z $site_payload ] && \
{ echo site_payload is not set. Deleting VM ; del_vm ; exit 1 ; }

case $install_method in
	raw|iso|img|distset) # objdir
		continue
	;;
	*)
		echo install_method is not set. Deleting VM
		del_vm
		exit 1
esac

case $disk0_type in
	dev|img|zvol) # iscsi|nfs
		continue
	;;
	*)
		echo disk0_type is not set. Deleting VM
		del_vm
		exit 1
esac

# VM directory structure and customized configuration file are now in place


### STEP TWO: Fetch raw image, ISO, IMG or distribution sets ###

# This is install_method agnostic
# Avoiding the 8.4 dist set layout
# pv? dpv?
# Maybe fetch size check against the ondisk one to make sure it is correct?
# Note FreeBSD timestamp files, reproducable builds...

echo
echo Fetching install media if not present in $host_distdir

for distset in $site_payload; do
	if [ -f $host_distdir/$site_path$distset ]; then # File is present
		echo
		echo $host_distdir$site_path$distset already exists locally
		fetchexit="0"
	else
		mkdir -p $host_distdir$site_path # Harmless if present
		echo
		echo $host_distdir$site_path$distset is missing. Fetching

# Consider fetch -m mirror mode which verifies payload size BUT would not
# allow for offline use. gjb says there may be a timestamp check

		fetch --no-verify-peer -m $install_site$site_path$distset -o \
			$host_distdir/$site_path/
			fetchexit=$?

		[ "$fetchexit" -gt 0 ] && \
		 	{ echo Distribution set did not fetch. Deleting VM ; \
				del_vm ; exit 1 ; }
	fi
done

# Make sure fetchexit is initialized
[ "$fetchexit" -gt 0 ] && \
{ echo Distribution set did not fetch. Deleting VM ; del_vm ; exit 1 ; }

echo
echo Expanding or copying the payload as necessary

# Note that gunzip will ignore endings that it does not recognize
# libarchive should do this but not the tar front end
# Consider fetch size check over a given size to distinguish
# text file answers, errors, redirects...
# Does fetch handle redirect output? ( earlier download above )

echo Checking if $host_distdir/$site_path/$site_payload is compressed
filetype=$( f_filetype "$host_distdir/$site_path/$site_payload" )

echo Download appears to be type $filetype according to f_filetype

payload_compressed="" # Override if set in an old-style template

case $filetype in
	.bz2) echo Handling .bz2
		payload_compressed="YES"
# Why does this test sometimes work with ! and sometimes not?
		if [ ! -f $host_distdir/$site_path/$site_payload.unc ]; then
			echo Expanding $host_distdir/$site_path/$site_payload \
			to $host_distdir/$site_path/$site_payload.unc
			gunzip -c -k $host_distdir/$site_path/$site_payload > \
			$host_distdir/$site_path/$site_payload.unc || \
		{ echo Image extraction failed. Deleting VM ; del_vm ; exit 1 ; }
		fi
	;;
	.Z) echo Handling .Z
		payload_compressed="YES"
# Why does this test sometimes work with ! and sometimes not?
		if [ ! -f $host_distdir/$site_path/$site_payload.unc ]; then
			echo Expanding $host_distdir/$site_path/$site_payload \
			to $host_distdir/$site_path/$site_payload.unc
			gunzip -c -k $host_distdir/$site_path/$site_payload > \
				$host_distdir/$site_path/$site_payload.unc || \
		{ echo Extraction failed. Deleting VM ; del_vm ; exit 1 ; }
		fi
	;;
	.gz) echo Handling .gz
		payload_compressed="YES"
# Why does this test sometimes work with ! and sometimes not?
		if [ ! -f $host_distdir/$site_path/$site_payload.unc ]; then
			echo Expanding $host_distdir/$site_path/$site_payload \
			to $host_distdir/$site_path/$site_payload.unc
			gunzip -c -k $host_distdir/$site_path/$site_payload > \
			$host_distdir/$site_path/$site_payload.unc || \
		{ echo Extraction failed. Deleting VM ; del_vm ; exit 1 ; }
		fi
	;;
	.xz) echo Handling .xz
		payload_compressed="YES"
# Why does this test sometimes work with ! and sometimes not?
		if [ ! -f $host_distdir/$site_path/$site_payload.unc ]; then
			echo Expanding $host_distdir/$site_path/$site_payload \
			to $host_distdir/$site_path/$site_payload.unc
			unxz -c -k $host_distdir/$site_path/$site_payload > \
			$host_distdir/$site_path/$site_payload.unc || \
		{ echo Extraction failed. Deleting VM ; del_vm ; exit 1 ; }
		fi
	;;
	.zip) echo Handling .zip
		payload_compressed="YES"
# Why does this test sometimes work with ! and sometimes not?
		if [ ! -f $host_distdir/$site_path/$site_payload.unc ]; then
			echo Expanding $host_distdir/$site_path/$site_payload \
			to $host_distdir/$site_path/$site_payload.unc
			gunzip -c -k $host_distdir/$site_path/$site_payload > \
			$host_distdir/$site_path/$site_payload.unc || \
		{ echo Extraction failed. Deleting VM ; del_vm ; exit 1 ; }
		fi
	;;
	Uncompressed)
		echo $host_distdir/$site_path/$site_payload not compressed
		payload_compressed="NO"
# A wildcard is somewhat pointless as we are relying on our own f_filetype
esac

# NB! We're looking for .unc not .iso and what not
# Done with downloading and decompressing the ISO or image
# Do we end with .iso or .unc?

# Consider text/html; charset=us-ascii for redirects and errors
# We could check return values but will check for the desired result

ending="" # Clear the variable
if [ $payload_compressed = "YES" ]; then
	ending=".unc"
fi


### STEP THREE : VM Storage Preparation ###

echo ; echo Preparing VM storage

case $install_method in
	raw)
		case $disk0_type in
			img)
				if [ "$disk0_size" = "" ]; then
echo Copying VM raw image $host_distdir/$site_path/${site_payload}$ending to \
	$host_vmdir$vm_name/disk0.img
			cp -p $host_distdir/$site_path/${site_payload}$ending \
			$host_vmdir$vm_name/disk0.img || \
{ echo Image failed to copy or link. Deleting VM ; del_vm ; exit 1 ; }
				else # disk0_size is set

echo Determining the size of $host_distdir/$site_path/${site_payload}$ending
payload_size=$( stat -f%z $host_distdir/$site_path/${site_payload}$ending ) || \
{ echo Could not determine payload size. Deleting VM ; del_vm ; exit 1 ; }

	disk_size=$( f_dehumanize $disk0_size ) || \
		{ echo disk0_size invalid. Deleting VM ; del_vm ; exit 1 ; }

				if [ $disk_size -gt $payload_size ]; then
					disk0_size=$disk_size
				else
					disk0_size=$payload_size
				fi

				fi # End disk0_blocksize

echo Running truncate -s $disk0_size $host_vmdir$vm_name/disk0.img
			truncate -s $disk0_size $host_vmdir$vm_name/disk0.img
			[ -w $host_vmdir$vm_name/disk0.img ] || \
				{ echo $host_vmdir$vm_name/disk0.img \
			failed to truncate. Deleting VM ; del_vm ; exit 1 ; }
			# conv=notrunc = preserve existing blocks on larger img

echo Running dd if=$host_distdir/$site_path/${site_payload}$ending \
	of=$host_vmdir$vm_name/disk0.img conv=notrunc bs=1m

# NB! Determine blocksize from config and add to dd? Pick one if not specified?

			dd if=$host_distdir/$site_path/${site_payload}$ending \
of=$host_vmdir$vm_name/disk0.img conv=notrunc bs=1m || \
			{ echo dd failed. Deleting VM ; del_vm ; exit 1 ; }
# NB! Determine if a gpart resize is needed?
# gpart resize -i 3 ada0 ; growfs /
# https://www.freebsd.org/doc/handbook/disks-growing.html

			;; # End install_method: raw: disk0_type img
			dev)
echo dev installation not yet implemented. Deleting VM
# NB! Determine if a gpart resize is needed
# gpart resize -i 3 ada0 ; growfs /

# https://www.freebsd.org/doc/handbook/disks-growing.html
del_vm ; exit 1
			;; # End install_method: raw: disk0_type dev
			zvol)

# Determine the requested disk size from the configuration file
payload_size=$( stat -f%z $host_distdir/$site_path/${site_payload}$ending ) || \
{ echo Could not determine payload size. Deleting VM ; del_vm ; exit 1 ; }

echo Verifying if a custom disk0_size is set
			disk_size=""
			if [ "$disk0_size" ]; then 
echo Custom disk0_size of $disk0_size is set
			disk_size=$( f_dehumanize $disk0_size ) || \
		{ echo disk0_size invalid. Deleting VM ; del_vm ; exit 1 ; }

				if [ "$disk_size" -gt "$payload_size" ]; then
					disk0_size=$disk_size
				fi
			else
				disk0_size=$payload_size
			fi
echo Verifying if a custom disk0_blocksize is set
			disk_blocksize=""
			if [ "$disk0_blocksize" ]; then 
echo Custom disk0_blocksize of $disk0_blocksize is set
		disk_blocksize=$( f_dehumanize $disk0_blocksize ) || \
	 { echo disk0blocksize invalid. Deleting VM ; del_vm ; exit 1 ; }
echo disk0_blocksize of $disk0_blocksize or $disk_blocksize bytes is set
			else
echo Using the default ZFS blocksize of 8192 bytes
				disk_blocksize=8192 # ZFS default of 128k
# NB! Double check this value
			fi

			# Sanitize adjusted disk0_size based on disk_blocksize
			disk0_size=$(( $disk0_size / $disk_blocksize ))
			disk0_size=$(( $disk0_size + 1 ))
			disk0_size=$(( $disk0_size * $disk_blocksize ))

echo Creating zvol $host_zpool$host_vmdir$vm_name/disk0 with \
	zfs create -s -o volblocksize=$disk_blocksize -V $disk0_size \
	$host_zpool$host_vmdir$vm_name/disk0

		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
			{ zfs create -s -o volblocksize=$disk_blocksize \
				-V $disk0_size \
				$host_zpool$host_vmdir$vm_name/disk0 ; }
		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
		{ echo zvol failed to create. Deleting VM ; del_vm ; exit 1 ; }

echo Running dd if=$host_distdir/$site_path/${site_payload}$ending \
	of=/dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 conv=notrunc bs=1m

# NB! Determine blocksize from config and add to dd? Pick one if not specified?

			dd if=$host_distdir/$site_path/${site_payload}$ending \
of=/dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 conv=notrunc bs=1m || \
			{ echo dd failed. Deleting VM ; del_vm ; exit 1 ; }

			;; # End install_method: raw: disk0_type zvol
	esac # End install_method: raw: disk0_type
	echo ; echo "You can boot your VM with:"
	echo ; echo "service vm onestart $vm_name"
	echo "service vm oneattach $vm_name	\# Serial Console"
	echo "service vm onevnc $vm_name	\# VNC Console, if appropriate"
	echo
		exit 0
	;; # End install_method: raw

	iso|img)
		case $disk0_type in
			img)
# Check if it exists, not sure when that might happen but would allow the
# operator to create a storage device during the vi customization stage
		if [ ! -f $host_vmdir/$vm_name/disk0.img ]; then
		echo
		echo Truncating $host_vmdir/$vm_name/disk0.img
# BUG to consider: fixed in HEAD: a 'dd' option for use with 'tar'
		[ -z $disk0_size ] && \
{ echo disk0_size is not set. Deleting VM ; del_vm ; exit 1 ; }

echo Running truncate -s $disk0_size $host_vmdir/$vm_name/disk0.img
		truncate -s $disk0_size $host_vmdir/$vm_name/disk0.img
# NB! I thought truncate could set a blocksize... use 'dd'?
		[ -f $host_vmdir/$vm_name/disk0.img ] || \
	{ echo Disk image failed to create. Deleting VM ; del_vm ; exit 1 ; }
		fi

			;; # End install_method: iso|img: disk0_type img
			dev)
				continue
			;; # End install_method: iso|img: disk0_type dev
			zvol)

		# Check if disk0_blocksize is set
		disk_blocksize=""
		if [ "$disk0_blocksize" ]; then 
		disk_blocksize=$( f_dehumanize $disk0_blocksize ) || \
	 { echo Verify disk0_blocksize. Deleting VM ; del_vm ; exit 1 ; }
		disk_blocksize="-o volblocksize=$disk_blocksize"
		fi

echo Creating zvol $host_zpool$host_vmdir$vm_name/disk0 with \
	zfs create -s $disk_blocksize -V $disk0_size \
	$host_zpool$host_vmdir$vm_name/disk0
		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
		{ zfs create -s $disk_blocksize -V $disk0_size \
			$host_zpool$host_vmdir$vm_name/disk0 ; }
		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
	{ echo zvol failed to create. Deleting VM ; del_vm ; exit 1 ; }
			;; # End install_method: iso|img: disk0_type zvol
		esac # End install_method: iso|img: disk0_type

echo Linking $host_distdir/$site_path/${site_payload}$ending \
	to $host_vmdir/$vm_name/install.$install_method
# Alternative: cp -p because some containers may complain
		ln -sf $host_distdir/$site_path/${site_payload}$ending \
			$host_vmdir/$vm_name/install.$install_method || \
{ echo Image failed to copy or link. Deleting VM ; del_vm ; exit 1 ; }

	echo ; echo "You can boot your VM and begin installation with:"
	echo ; echo "service vm oneinstall $vm_name"
	echo "service vm oneattach $vm_name	\# Serial Console"
	echo "service vm onevnc $vm_name	\# VNC Console, if appropriate"
	echo
	echo Some installers will require a "stop" after installation
	echo
		exit 0
	;; # End install_method: iso|img

	distset|objdir)
		case $disk0_fs in
			ufs|zfs) continue
			;;
			*) echo disk0_fs not set. Deleting VM ; del_vm ; exit 1
		esac
			case $vm_dev_util in
			fdisk|gpart) continue
			;;
			*) echo vm_dev_util not set. Deleting VM ; del_vm ; exit 1
		esac

		case $vm_dev_layout in
			mbr|gpt) continue
			;;
		*) echo vm_dev_layout not set. Deleting VM ; del_vm ; exit 1
		esac

		case $disk0_type in
			img)
# Check if it exists, not sure when that might happen but would allow the
# operator to create a storage device during the vi customization stage

		if [ ! -f $host_vmdir/$vm_name/disk0.img ]; then
		echo
echo Running truncate -s $disk0_size $host_vmdir/$vm_name/disk0.img
# BUG to consider: fixed in HEAD: a 'dd' option for use with 'tar'
		[ -z $disk0_size ] && \
{ echo disk0_size is not set. Deleting VM ; del_vm ; exit 1 ; }
		truncate -s $disk0_size $host_vmdir/$vm_name/disk0.img
# NB! I thought truncate could set a blocksize... use 'dd'?
		[ -f $host_vmdir/$vm_name/disk0.img ] || \
	{ echo Disk image failed to create. Deleting VM ; del_vm ; exit 1 ; }
		fi

		vm_device=$( mdconfig -af $host_vmdir$vm_name/disk0.img ) ||
		{ echo "disk0.img failed to attach. Exiting" ; exit 1 ; }

			;; # End install_method: distset|objdir: disk0_type img
			dev)
				continue
			;; # End install_method: distset|objdir: disk0_type dev
			zvol)
echo Verifying if a custom disk0_blocksize is set
		disk_blocksize=""
		if [ "$disk0_blocksize" ]; then 
		disk_blocksize=$( f_dehumanize $disk0_blocksize ) || \
	 { echo Verify disk0_blocksize. Deleting VM ; del_vm ; exit 1 ; }
		disk_blocksize="-o volblocksize=$disk_blocksize"
		fi

echo Creating zvol $host_zpool$host_vmdir$vm_name/disk0
		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
		{ zfs create -s $disk_blocksize -V $disk0_size \
			$host_zpool$host_vmdir$vm_name/disk0 ; }
		[ -e /dev/zvol/$host_zpool$host_vmdir$vm_name/disk0 ] || \
	{ echo zvol failed to create. Deleting VM ; del_vm ; exit 1 ; }
		vm_device=zvol/$host_zpool$host_vmdir$vm_name/disk0

			;; # End install_method: distset|objdir: disk0_type zvol

		esac # End install_method: distset|objdir: disk0_type

echo ; echo Prefixing $vm_device as /dev/$vm_device
vm_device=/dev/$vm_device

echo ; echo The resulting VM device is $vm_device
echo ; echo Verifying that $vm_device exists
if [ -e $vm_device ]; then
	echo Using $vm_device
else
	echo VM device $vm_device failed to initialize. Exiting
	exit 1
fi

echo ; echo Initializing the vm_mountpoint variable as
echo $host_vmdir/$vm_name/mnt/
vm_mountpoint=$host_vmdir/$vm_name/mnt/

# Note that vm_dev_util and vm_dev_layout were checked above
echo ; echo Running f_${vm_dev_util}_${vm_dev_layout}_layout
f_${vm_dev_util}_${vm_dev_layout}_layout_preflight $vm_device
f_${vm_dev_util}_${vm_dev_layout}_layout $vm_device
f_${vm_dev_util}_${vm_dev_layout}_layout_debug $vm_device

echo ; echo Running f_check_gpt_alignment $vm_device
f_check_gpt_alignment $vm_device && echo Partitions are aligned
# BUG: Make conditional, report if not alighed

# pointless here if a zvol. Move to function, need to test either way
#echo ; echo Running file on $host_vmdir/$vm_name/${vm_name}.img
#file $host_vmdir/$vm_name/${vm_name}.img

echo ; echo Running f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_boot
f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_boot_preflight $vm_device
f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_boot $vm_device
f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_boot_debug $vm_device

# again, pointless here
#echo ; echo Running file on $host_vmdir/$vm_name/${vm_name}.img
#file $host_vmdir/$vm_name/${vm_name}.img
# Push test to function?

#f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_bootmgr_preflight $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_bootmgr $vm_device
#f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_bootmgr_debug $vm_device
#file ${host_vmdir}/${vm_name}/${vm_name}.img

echo ; echo Formatting ZFS or UFS storage as appropriate
if [ "$disk0_fs" = "zfs" ]; then

	# Name the VM's pool in a non-conflicting way
	# One pool name for all VM's would be a dissaster when mounted on host
	vm_pool=${vm_name}pool

	echo ; echo Running f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_part
	f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_part_preflight $vm_device
	f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_part $vm_device
	f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_part_debug $vm_device

	echo ; echo Destroying the pool just in case
	zpool destroy $vm_pool >/dev/null 2>&1

	case $vm_dev_layout in
		mbr)
			echo Destroying the gnop just in case
			gnop destroy -f ${vm_device}s1a.nop >/dev/null 2>&1
		;;
		gpt)
			echo Destroying the gnop just in case
			gnop destroy -f ${vm_device}p2.nop >/dev/null 2>&1
		;;
		*)
		echo Invalid VM device layout
		return
	esac

	# case layout=mbr - doesn't seem necessary
	#echo manually-adding-boot-code
	#dd if=/boot/zfsboot of=${vm_device}s1a skip=1 seek=1024

	echo ; echo Running f_${vm_dev_util}_${vm_dev_layout}_zpool
	f_${vm_dev_util}_${vm_dev_layout}_zpool_preflight $vm_device $vm_pool $vm_mountpoint
	f_${vm_dev_util}_${vm_dev_layout}_zpool $vm_device $vm_pool $vm_mountpoint
	f_${vm_dev_util}_${vm_dev_layout}_zpool_debug $vm_device $vm_pool $vm_mountpoint

	echo ; echo Running zpool import
	zpool import

echo ; echo Running zpool import -o cachefile=none -R $vm_mountpoint $vm_pool
	zpool import -o cachefile=none -R $vm_mountpoint $vm_pool

	echo ; echo Running zpool list pipe grep $vm_pool
	zpool list | grep $vm_pool
	zfs list | grep $vm_pool
	echo Running mount pipe grep $vm_pool
	mount | grep $vm_pool

else # UFS

# BUG: Missing MBR variant. Does this even belong here?
#	echo
#	echo Running f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_newfs
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_newfs_preflight $vm_device
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_newfs $vm_device
#	f_"$vm_dev_util"_"$vm_dev_layout"_"$disk0_fs"_newfs_debug $vm_device

	case $vm_dev_layout in
		mbr)
			echo
			echo Running f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_bootable
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_bootable_preflight $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_bootable $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_bootable_debug $vm_device
		;;
		gpt)
			echo
			echo Running f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_preflight $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs $vm_device
			f_${vm_dev_util}_${vm_dev_layout}_${disk0_fs}_newfs_debug $vm_device
		;;
		*)
		echo Invalid VM device layout
		return
	esac

	echo ; echo Running ls $vm_device asterisk pipe head
	ls ${vm_device}* | head

echo ; echo Mounting UFS-based storage if requested
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
echo ; echo Running mountpoint checks to avoid extracting to root
if [ "$vm_mountpoint" = "" ]; then
	echo We do not want to install to root. Deleting VM
	del_vm
	exit 1
elif [ "$vm_mountpoint" = "/" ]; then
	echo We do not want to install to root. Deleting VM
	del_vm
	exit 1
fi

echo ; echo Determining if install method is distribution set or src/obj
if [ "$install_method" = "distset" ]; then
	echo ; echo Running distribution set extraction loop
	for distset in $site_payload; do
		f_installset_preflight $host_distdir/$site_path/$distset \
			$vm_mountpoint
		f_installset $host_distdir/$site_path/$distset $vm_mountpoint
	f_installset_debug $host_distdir/$site_path/$distset $vm_mountpoint
	done
elif [ "$install_method" = "objdir" ]; then
echo ; echo Verifying that sources and a built world and kernel are present
	if [ ! -f $vm_objdir/Makefile ]; then
		echo Sources are not present in ${vm_objdir}. Deleting VM
		del_vm
		exit 1
# NB! Rethink this: only use a custom src and obj directories
	elif [ ! -d /usr/obj/usr ]; then
		echo Built world not present in /usr/obj/. Deleting VM
		del_vm
		exit 1
	elif [ ! -d /usr/obj/usr/src/sys ]; then
		echo Built kernel not present in /usr/obj/. Deleting VM
		del_vm
		exit 1
	fi

	echo ; echo Changing to the source directory for an obj installation
	cd $vm_objdir
	echo ; echo Running make installworld to $vm_mountpoint
	make installworld DESTDIR=$vm_mountpoint
	echo ; echo Running make installkernel to $vm_mountpoint
	make installkernel DESTDIR=$vm_mountpoint
	echo ; echo Running make distribution to $vm_mountpoint
	make distribution DESTDIR=$vm_mountpoint
else
	echo ; echo Install method not set. Deleting VM
	del_vm
	exit 1
fi

echo ; echo Running ls $vm_mountpoint
ls $vm_mountpoint

echo ; echo Configuring loader
f_config_loader_conf_preflight $vm_mountpoint
f_config_loader_conf $vm_mountpoint
f_config_loader_conf_debug $vm_mountpoint

echo ; echo Configuing fstab
if [ "$disk0_fs" = "zfs" ]; then
	f_config_zfs_fstab_preflight $vm_mountpoint
	f_config_zfs_fstab $vm_mountpoint
	f_config_zfs_fstab_debug $vm_mountpoint
else
	f_config_"$vm_dev_layout"_fstab_preflight $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab $vm_mountpoint
	f_config_"$vm_dev_layout"_fstab_debug $vm_mountpoint
fi

echo ; echo Configuring time zone
f_config_tz_preflight $vm_mountpoint $vm_timezone
f_config_tz $vm_mountpoint $vm_timezone
f_config_tz_debug $vm_mountpoint $vm_timezone

echo ; echo Configuring rc.conf
f_config_rc_conf_preflight $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw
f_config_rc_conf_debug $vm_mountpoint $vm_hostname $vm_ipv4 $vm_gw

echo ; echo Configuring resolv.conf
if [ ! "$vm_ipv4" = "" ]; then
f_config_resolv_conf_preflight $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf $vm_mountpoint $vm_searchdomain $vm_dns
f_config_resolv_conf_debug $vm_mountpoint $vm_searchdomain $vm_dns
fi

echo ; echo Enabling ssh root access
f_config_sshd_root_preflight $vm_mountpoint
f_config_sshd_root $vm_mountpoint
f_config_sshd_root_debug $vm_mountpoint

echo ; echo Setting root password
f_set_password_preflight $vm_password $vm_mountpoint
f_set_password $vm_password $vm_mountpoint
f_set_password_debug $vm_password $vm_mountpoint


### LAST CHANCE TO MODIFIY THE VM FILESYSTEM ###
### Modify or copy in files as appropriate ###

echo ; echo Exporting or unmounting
if [ "$disk0_fs" = "zfs" ]; then
	echo ; echo Exporting pool $vm_pool
	zpool export $vm_pool
else
	echo ; echo Unmounting $vm_mountpoint
	umount -f $vm_mountpoint
fi

echo ; echo Detaching memory device $vm_device
mdconfig -du $vm_device

	echo ; echo "You can boot your VM with:"
	echo ; echo "service vm onestart $vm_name"
	echo "service vm oneattach $vm_name	\# Serial Console"
	echo "service vm onevnc $vm_name	\# VNC Console, if appropriate"
	echo
		exit 0

esac # End install_method

# END GIANT CASE STATEMENT
