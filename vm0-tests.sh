#!/bin/sh

# This is a simple test to manally provision vm0, destroy it and then
# automatically provision and start it for testing purposes.

echo "Checking usage"
/usr/local/etc/rc.d/vm
echo "Stopping vm0"
/usr/local/etc/rc.d/vm stop vm0
echo "Removing vm0 image and iso"
rm /usr/local/vm/vm0/vm0.i*
echo "Running through the provision steps manually"
echo "Fetching vm0"
/usr/local/etc/rc.d/vm fetch vm0 
echo "Formatting vm0"
/usr/local/etc/rc.d/vm format vm0
echo "Installing vm0"
/usr/local/etc/rc.d/vm install vm0
echo "Mounting vm0"
/usr/local/etc/rc.d/vm mount vm0
echo "Unmounting vm0"
/usr/local/etc/rc.d/vm umount vm0
echo "Loading vm0"
/usr/local/etc/rc.d/vm load vm0
echo "Booting vm0"
/usr/local/etc/rc.d/vm boot vm0
echo "Stopping vm0"
/usr/local/etc/rc.d/vm stop vm0
echo "Removing vm0 image and iso"
rm /usr/local/vm/vm0/vm0.i*
echo "Provisioning vm0"
/usr/local/etc/rc.d/vm provision vm0
echo "Starting vm0"
/usr/local/etc/rc.d/vm start vm0
#echo "Stopping vm0"
#/usr/local/etc/rc.d/vm stop vm0
