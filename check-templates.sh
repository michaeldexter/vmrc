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
# Title: Check Templates Script
# Version: v.0.8

# This is a simple script that use 'wget -q --spider' to verify that all of
# the downloadable images in the templates are still accessible.

# Requires wget - easily replaced with fetch -s, output supression and return check

host_distdir="/usr/local/vmrc/templates/"

for link in "$host_distdir"/*; do

	. $link

	case $install_method in
	rawimg|isoimg)
		fetch -s $install_site/$site_path/$site_payload || \
		echo "$link: $install_site/$site_path/$site_payload missing!"
	;;
	distset)
	for distset in $site_payload; do
		fetch -s $install_site/$site_path/$distest || \
		echo "$link: $install_site/$site_path/$site_payload missing!"
	done
	;;
	obj)
	echo "Template specifies /usr/obj"
esac
done

exit 0
