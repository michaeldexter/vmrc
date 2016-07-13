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
# Title: Check Templates Script
# Version: v.0.9.3

# This is a simple script that used 'wget -q --spider' to verify that all of
# the downloadable images in the templates are still accessible.
# fetch(1) has replated wget in this script

# Consider reading from vmrc.conf
host_distdir="/vmrc/templates/"

for template in "$host_distdir"/*; do

	. $template
	echo "Checking template $template"

	case $install_method in
	rawimg|isoimg)
# Note that we have URLs: ftp://ftp.freebsd.org...
#		echo "Running host $install_site just in case"
#		host $install_site
		echo "Running fetch -s $install_site/$site_path/$site_payload"
		fetch -s $install_site/$site_path/$site_payload || \
		{ echo "$template: $install_site/$site_path/$site_payload missing!"
		echo "Adding _fail suffix to $template"
                mv $template ${template}_fail
		}
	;;
	distset)
	for distset in $site_payload; do
#		echo "Running host $install_site just in case"
#		host $install_site
		echo "Running fetch -s $install_site/$site_path/$site_payload"
		fetch -s $install_site/$site_path/$distest || \
		{ echo "$template: $install_site/$site_path/$site_payload missing!"
		echo "Adding _fail suffix to $template"
		mv $template ${template}_fail
		}
	done
	;;
	obj)
	echo "Template specifies /usr/obj"
esac
done

exit 0
