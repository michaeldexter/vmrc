#!/bin/sh

# Useful while testing, uncomment as appropriate

echo "Running: mkdir -p /usr/local/etc/rc.d/"
mkdir -p /usr/local/etc/rc.d/
echo "Running: cp vm /usr/local/etc/rc.d/"
cp vm /usr/local/etc/rc.d/
echo "Running: chmod a+x /usr/local/etc/rc.d/vm"
chmod a+x /usr/local/etc/rc.d/vm
echo "Running: chmod a-w /usr/local/etc/rc.d/vm"
chmod a-w /usr/local/etc/rc.d/vm
echo "Running: cp vm.conf /usr/local/etc/"
cp vm.conf /usr/local/etc/

echo "Running: creating /usr/local/vmrc directories"
mkdir -p /usr/local/vmrc/vm
mkdir -p /usr/local/vmrc/distributions
mkdir -p /usr/local/vmrc/templates
