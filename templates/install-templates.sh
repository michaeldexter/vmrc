#!/bin/sh

echo
echo "This will populate /usr/local/vmrc/templates"
echo
echo "See instructions.txt for more information"

if [ ! -d /usr/local/vmrc/templates ]; then
	echo "Creating /usr/local/vmrc/templates"
	mkdir -p /usr/local/vmrc/templates
fi

echo "Running: cp -rp t_* /usr/local/vmrc/templates/"
cp -rp t_* /usr/local/vmrc/templates/

echo "Running: cp -rp virtio* /usr/local/vmrc/templates/"
cp -rp virtio* /usr/local/vmrc/templates/

exit

# From the provision(ing) days:

echo "Running: mkdir /usr/local/vmrc/vm/vm0"
mkdir -p /usr/local/vmrc/vm/vm0
echo "Running: mkdir /usr/local/vmrc/vm/vm0/mnt"
mkdir -p /usr/local/vmrc/vm/vm0/mnt

#echo "Running: cp templates/t_freebsd10 /usr/local/vmrc/vm/vm0/vm0.conf"
#echo
#cp templates/t_freebsd10 /usr/local/vmrc/vm/vm0/vm0.conf

# Note that FreeNAS, pfSense and OpenBSD must be fetched first

# All others default to "nmdm" consoles
mkdir /usr/local/vmrc/vm/vm1
cp templates/t_freebsd92 /usr/local/vmrc/vm/vm1/vm1.conf

mkdir /usr/local/vmrc/vm/vm2
cp templates/t_freebsd92stable /usr/local/vmrc/vm/vm2/vm2.conf

mkdir /usr/local/vmrc/vm/vm3
cp templates/t_freebsd11current /usr/local/vmrc/vm/vm3/vm3.conf

mkdir /usr/local/vmrc/vm/freenas4
cp templates/t_freenas /usr/local/vmrc/vm/freenas4/freenas4.conf

mkdir /usr/local/vmrc/vm/pfsense5
cp templates/t_pfsense /usr/local/vmrc/vm/pfsense5/pfsense5.conf

mkdir /usr/local/vmrc/vm/openbsd6
cp templates/t_openbsd /usr/local/vmrc/vm/openbsd6/openbsd6.conf

mkdir /usr/local/vmrc/vm/ubuntu7
cp templates/t_ubuntu1310 /usr/local/vmrc/vm/ubuntu7/ubuntu7.conf

mkdir /usr/local/vmrc/vm/ubuntu8
cp templates/t_ubuntu1304 /usr/local/vmrc/vm/ubuntu8/ubuntu8.conf

mkdir -p /usr/local/vmrc/vm/centos9
cp templates/t_centos65 /usr/local/vmrc/vm/centos9/centos9.conf
