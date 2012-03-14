#!/bin/bash 

if [ ! -d /var/tmp/isos ]; then
  mkdir /var/tmp/isos
  #wget http://ftp.sh.cvut.cz/MIRRORS/centos/6.2/isos/x86_64/CentOS-6.2-x86_64-netinstall.iso
  wget -P /var/tmp/isos/ http://192.168.122.1/ks/CentOS-6.2-x86_64-netinstall.iso
  #wget http://people.debian.org/~aurel32/qemu/amd64/debian_lenny_amd64_standard.qcow2
  wget -P /var/tmp/isos/ http://192.168.122.1/ks/debian_lenny_amd64_standard.qcow2
fi

(
set -x
COUNTER=0
for IMAGE in /var/tmp/isos/CentOS-6.2-x86_64-netinstall.iso /var/tmp/isos/debian_lenny_amd64_standard.qcow2; do
  for I in `seq -s " " 10`; do
    COUNTER=$((COUNTER+1))
    echo "*** $IMAGE: $I / $COUNTER"
    glance add name="My Image - $COUNTER" is_public=true < $IMAGE
    glance details $COUNTER
    glance show $COUNTER
    glance index
    glance update $COUNTER is_public=false
    glance update $COUNTER is_public=true
    wget -q http://0.0.0.0:9292/v1/images/$COUNTER -O - > /dev/null
    glance delete $COUNTER -f  
  done
done
) 2>&1 | tee /tmp/glance_log_tests.log