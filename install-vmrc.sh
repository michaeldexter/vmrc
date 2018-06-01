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
# Title: virtual machine rc script installation script
# Version: v.0.9.3
#
# Verbose script to install the vmrc rc script and supporting files
#
################################################################## USAGE
#
# Configure vmrc.conf as appropriate
#
# As root run: sh install-vmrc.sh
#
########################################################################

# suid=$( id -u ) ; [ "$suid" = "0" ] || \
[ `id -u` -ne 0 ] && \
	{ echo Must be excuted with root privileges. Exiting ; exit 1 ; }

[ -f ./vmrc.conf ] || \
	{ echo ./vmrc.conf does not exist. Exiting ; exit 1 ; }
[ -r ./vmrc.conf ] || \
	{ echo ./vmrc.conf is not readable. Exiting ; exit 1 ; }
sh -n ./vmrc.conf > /dev/null 2>&1 || \
	{ echo ./vmrc.conf failed to parse. Exiting ; exit 1 ; }
echo ; echo Reading ./vmrc.conf
. ./vmrc.conf > /dev/null 2>&1 || \
	{ echo ./vmrc.conf failed to source. Exiting ; exit 1 ; }

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

# Verify that the paths to not conflict

if [ "$host_templates" = "$host_distdir" ]; then
	echo host_templates and host_distdir conflict. Exiting ; exit 1 ;

elif [ "$host_templates" = "$host_vmdir" ]; then
	echo host_templates and host_vmdir conflict. Exiting ; exit 1 ;

elif [ "$host_distdir" = "$host_vmdir" ]; then
	echo host_distdir and host_vmdir conflict. Exiting ; exit 1 ;
fi


# Install vm rc script and vmrc.conf to established FreeBSD destinations

echo ; echo Running cp vm /usr/local/etc/rc.d/ or init.d/
service --version > /dev/null 2>&1
if [ $? = 0 ]; then
	cp vm /usr/local/etc/init.d/
	[ -f /usr/local/etc/init.d/vm ] || \
		{ echo The vm rc script failed to copy. Exiting ; exit 1 ; }
else
	cp vm /usr/local/etc/rc.d/
	[ -f /usr/local/etc/rc.d/vm ] || \
		{ echo The vm rc script failed to copy. Exiting ; exit 1 ; }
fi

# May as well as combine these with a numeric mask
echo Running chmod o+x /usr/local/etc/rc.d/vm
chmod a+x /usr/local/etc/rc.d/vm

echo Running chmod a-w /usr/local/etc/rc.d/vm
chmod a-w /usr/local/etc/rc.d/vm

# Intentionally overwriting an existing vmrc.conf should the syntax change
echo Running cp vmrc.conf /usr/local/etc/
cp vmrc.conf /usr/local/etc/

[ -f /usr/local/etc/vmrc.conf ] || \
	{ echo The vmrc.conf config file failed to copy. Exiting ; exit 1 ; }

echo
echo Creating vmrc directories or datasets specified in vmrc.conf as appropriate

# Abort if a zpool is requested but does not exist

	zpool get -pH name $host_zpool > /dev/null 2>&1
		[ $? -gt 0 ] && \
	{ echo Requested zpool $host_zpool does not exist. Exiting ; exit 1 ; }

# NB! FreeNAS sets the altroot property to "/mnt" for all new volumes to prevent
# collisions with the boot pool, freenas-boot.
# Solution: Glob off /mnt: echo ${host_vmdir#/mnt}

# Not what we want, but does work:
#host_zpool_altroot=$( zpool get -o value -Hp altroot $host_zpool )
#[ "$host_zpool_altroot" = "-" ] && $host_zpool_altroot=""

# Accomdate FreeNAS /mnt altroot, assuming that all VMs would be stored
# in a user-created pool (which by definition is under /mnt)

	if [ $( grep FreeNAS /etc/version > /dev/null 2>&1 ) ]; then
		# The FreeNAS altrool of /mnt/ will be pre-pended automatically
		echo Appears to be a FreeNAS host
		host_templates_mp=${host_templates#/mnt}
		host_distdir_mp=${host_distdir#/mnt}
		host_vmdir_mp=${host_vmdir#/mnt}
	else
		host_templates_mp=$host_templates
		host_distdir_mp=$host_distdir
		host_vmdir_mp=$host_vmdir
	fi

# NB! Would be nice to mention if existing directories are being used

# Attempt to create datasets if the requested zpool exists
if [ "$host_zpool" ]; then

[ -d $host_templates ] || \
	{ echo ; echo Creating the $host_templates dataset ; \
zfs create -p -o mountpoint=$host_templates_mp $host_zpool${host_templates%/} ; }
[ -d $host_templates ] || \
	{ echo The $host_templates dataset failed to create. \
	 Trying a directory instead ; \
	mkdir -p $host_templates ; }
[ -d $host_templates ] || \
	{ echo $host_templates failed to create. Exiting ; exit 1 ; }

[ -d $host_distdir ] || \
	{ echo ; echo Creating the $host_distdir dataset ; \
zfs create -p -o mountpoint=$host_distdir_mp $host_zpool${host_distdir%/} ; }
[ -d $host_distdir ] || \
	{ echo The $host_distdir dataset failed to create. \ 
	Trying a directory instead ; \
	mkdir -p $host_distdir ; }
[ -d $host_distdir ] || \
	{ echo $host_distdir failed to create. Exiting ; exit 1 ; }

[ -d $host_vmdir ] || \
	{ echo ; echo Creating the $host_vmdir dataset ; \
zfs create -p -o mountpoint=$host_vmdir_mp $host_zpool${host_vmdir%/} ; }
[ -d $host_vmdir ] || \
	{ echo The $host_vmdir dataset failed to create. \
	Trying a directory instead ; \
	mkdir -p $host_vmdir ; }
[ -d $host_vmdir ] || \
	{ echo $host_vmdir failed to create. Exiting ; exit 1 ; }

else # No zpool is specified in vmrc.conf - Quite redundant with the above

	[ -d $host_templates ] || \
	{ echo ; echo Creating $host_templates directory ; \
	mkdir -p $host_templates ; }
		[ -d $host_templates ] || \
		{ echo $host_templates failed to create. Exiting ; exit 1 ; }

	[ -d $host_distdir ] || \
	{ echo ; echo Creating $host_distdir directory ; \
	mkdir -p $host_distdir ; }

		[ -d $host_distdir ] || \
		{ echo $host_distdir failed to create. Exiting ; exit 1 ; }

	[ -d $host_vmdir ] || 
	{ echo ; echo Creating $host_vmdir directory ; \
	mkdir -p $host_vmdir ; }
		[ -d $host_vmdir ] || \
		{ echo $host_vmdir failed to create. Exiting ; exit 1 ; }
fi

echo ; echo Running cp -rp templates/* $host_templates
cp -rp templates/* $host_templates || \
	{ echo $host_templates failed to install. Exiting ; exit 1 ; }

echo ; echo vmrc installation complete ; echo

