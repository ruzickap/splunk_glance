#!/bin/bash 

HOST="127.0.0.1"

if [ ! -d /var/tmp/isos ]; then
  mkdir /var/tmp/isos
  #wget http://ftp.sh.cvut.cz/MIRRORS/centos/6.2/isos/x86_64/CentOS-6.2-x86_64-netinstall.iso
  wget -P /var/tmp/isos/ http://192.168.100.1/ks/CentOS-6.2-x86_64-netinstall.iso
fi

glance add --verbose name="My Image" is_public=true < /var/tmp/isos/CentOS-6.2-x86_64-netinstall.iso --host=$HOST
glance --verbose update 5 is_public=true --host=$HOST
