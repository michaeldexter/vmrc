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
# Title: virtual machine rc script installation script
# Version: v.0.7
#
# Verbose script to install the vmrc rc script and supporting files
#
################################################################## USAGE
#
# As root: sh install-vmrc.sh
#
########################################################################

# Keep in sync with /usr/local/vm.conf
host_vmroot="/usr/local/vmrc/"   # Directory for all vmrc components
host_vmdir="/usr/local/vmrc/vm/" # VM configurations, images and mount points
host_distdir="/usr/local/vmrc/distributions/" # OS Distributions
host_templates="/usr/local/vmrc/templates/"   # VM Templates

echo
echo Running mkdir -p /usr/local/etc/rc.d/
mkdir -p /usr/local/etc/rc.d/

echo
echo Running cp vm /usr/local/etc/rc.d/
cp vm /usr/local/etc/rc.d/

echo # May as well as combine these with a numeric mask
echo Running chmod a+x /usr/local/etc/rc.d/vm
chmod a+x /usr/local/etc/rc.d/vm

echo
echo Running chmod a-w /usr/local/etc/rc.d/vm
chmod a-w /usr/local/etc/rc.d/vm

echo
echo Running cp vm.conf /usr/local/etc/
cp vm.conf /usr/local/etc/

echo
echo Creating /usr/local/vmrc directories
mkdir -p $host_vmdir
mkdir -p $host_distdir
mkdir -p $host_templates

echo
echo Running cp -p templates/* $host_templates
cp -p templates/* $host_templates

echo
echo At a minimum, verify the network device in /usr/local/etc/vm.conf
echo
