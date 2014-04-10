#!/bin/sh

# Useful while testing, uncomment as appropriate

mkdir -p /usr/local/etc/rc.d/
cp ../vm /usr/local/etc/rc.d/
chmod a+x /usr/local/etc/rc.d/vm
chmod a-w /usr/local/etc/rc.d/vm
cp ../vm.conf /usr/local/etc/

mkdir -p /usr/local/vm/

echo "Alert! Only vm0 is installed by default and has a stdio console."
echo "You probably do NOT want to automatically boot to this but rather"
echo "a detached console such as type nmdm or tmux-detached."
echo
echo "See instructions.txt for more information"

# Set to a stdio console
mkdir /usr/local/vm/vm0
cp vm0.conf /usr/local/vm/vm0/

# All others default to "nmdm" consoles
#mkdir /usr/local/vm/vm1
#cp vm1.conf /usr/local/vm/vm1

#mkdir /usr/local/vm/vm2
#cp vm2.conf /usr/local/vm/vm2/

#mkdir /usr/local/vm/vm3
#cp vm3.conf /usr/local/vm/vm3/

#mkdir /usr/local/vm/freenas4
#cp freenas4.conf /usr/local/vm/freenas4/

#mkdir /usr/local/vm/pfsense5
#cp pfsense5.conf /usr/local/vm/pfsense5/

#mkdir /usr/local/vm/openbsd6
#cp openbsd6.conf /usr/local/vm/openbsd6

#mkdir /usr/local/vm/ubuntu7
#cp ubuntu7.conf /usr/local/vm/ubuntu7/

#mkdir /usr/local/vm/ubuntu8
#cp ubuntu8.conf /usr/local/vm/ubuntu8/

#mkdir -p /usr/local/vm/centos9
#cp centos9.conf /usr/local/vm/centos9/
