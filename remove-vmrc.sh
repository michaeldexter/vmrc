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
# Title: virtual machine rc script removal script
# Version: v.0.7
#
# Script to remove the vmrc rc script and supporting files
#
################################################################## USAGE
#
# As root: sh remove-vmrc.sh
#
########################################################################

echo
echo Running rm /usr/local/etc/rc.d/vm
rm /usr/local/etc/rc.d/vm

echo
echo Running rm /usr/local/etc/vm.conf
rm /usr/local/etc/vm.conf

echo
echo Removing the /usr/local/vmrc directory
chflags -R noschg /usr/local/vmrc/
rm -rf /usr/local/vmrc

echo
echo Deletion complete within the limits of available permissions
echo
