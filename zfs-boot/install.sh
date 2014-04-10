#!/bin/sh

cp /boot/userboot.so /boot/userboot.so.bak
cp userboot.so /boot/

cp /usr/sbin/bhyveload /usr/sbin/bhyveload.bak
cp bhyveload /usr/sbin/

