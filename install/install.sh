#!/bin/sh

# Useful while testing, uncomment as appropriate

echo "Running: mkdir -p /usr/local/etc/rc.d/"
mkdir -p /usr/local/etc/rc.d/
echo "Running: cp ../vm /usr/local/etc/rc.d/"
cp ../vm /usr/local/etc/rc.d/
echo "Running: chmod a+x /usr/local/etc/rc.d/vm"
chmod a+x /usr/local/etc/rc.d/vm
echo "Running: chmod a-w /usr/local/etc/rc.d/vm"
chmod a-w /usr/local/etc/rc.d/vm
echo "Running: cp ../vm.conf /usr/local/etc/"
cp ../vm.conf /usr/local/etc/

echo "Running: mkdir -p /usr/local/vm/"
mkdir -p /usr/local/vm/

echo
echo "Alert! Only vm0 is installed by default and has a stdio console."
echo "You probably do NOT want to automatically boot to this but rather"
echo "a detached console such as type nmdm or tmux-detached."
echo
echo "See instructions.txt for more information"

# Set to a stdio console
echo "Running: mkdir /usr/local/vm/vm0"
mkdir /usr/local/vm/vm0
echo "Running: cp vm0.conf /usr/local/vm/vm0/"
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
