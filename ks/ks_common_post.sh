#############################
# sshd + sudo
#############################
mkdir -vp /root/.ssh /home/pruzicka/.ssh
chown -vR pruzicka:pruzicka /home/pruzicka/.ssh
chmod 700 /root/.ssh /home/pruzicka/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs66C38OoKnVrAIwd3lF84Ln9RRuY91GzZvZY01YxbUZ4arCgPmRRp9L7LIXs1ivSS2LNcFhwWUb5xX9A8inRUggfzY5lFJdmDPTZ395AlpEuDM7NQ5ESCIH8HCPkMr+RmmPGIQxdh3BdDq5HcZK1Zg21dDRUu01E0MK2/I3Wrve4JbHH1B04yIDtjfJZzqNc002wzWz4SyfEcTW0GR8DelA/T2Uyw8A6cj0xY171nkbHzoKk3SEntL/KTJwxvYP0GbwDeiSg/aiq+dCMkCaiCZYgeb5YAlkyw3vcH5Kh5ODFrJkP4mQdjevW2CTU6DL5vvkj9v5uTwWnIG3KMyoe+Q== root@rhel60-00' >> /root/.ssh/authorized_keys
cp /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5sfhR4q7zN1fIiziPyKIExcW0kj2hNih5HgHfAZzWSgMf3B2mPq7N+O+X45DVHkLUlNx5IJaR2PtZvcIXZ8way++WXmhfi8IKCcf9KcbfcugTcyHScsQVrtZEzc1ymywx4YxSLwF9RZhDUYU+yTO4zV4q57jaJyOUQzFx9ZN7aazlLOQw3bMYyGJBZKL7dO43k7wL+eL7UpjzCm7nZZ/xAa8YngXM0ldkIRIhO2Hmh+WJ2B3SOQHEd/UunrGJL7ilVi8oIdo1SAFoLAIkk+15EyoWvplbmXnsSUMDMKjgyOWPAREDBN3LP+Va8O9n8TUmmLCBj7IfQX4u6UQ4+Mlv pruzicka@peru' >> /root/.ssh/authorized_keys
cat > /root/.ssh/config << EOF
Host *
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
User root
EOF

cp -v /root/.ssh/* /home/pruzicka/.ssh/
chmod 600 /root/.ssh/authorized_keys /home/pruzicka/.ssh/authorized_keys
restorecon -R -v /root/.ssh/ /home/pruzicka/.ssh/
echo "pruzicka  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

IP=`ifconfig eth0 | sed -n '/inet /{s/.*addr://;s/ .*//;p}'`
HOSTNAME_SHORT=`echo $HOSTNAME | sed 's/\([^.]*\).*/\1/'`
hostname $HOSTNAME

echo -e "${IP}\t\t$HOSTNAME $HOSTNAME_SHORT" >> /etc/hosts

sed -i.orig "s/^\(HOSTNAME=\).*/\1$HOSTNAME/" /etc/sysconfig/network
echo "NOZEROCONF=yes" >> /etc/sysconfig/network


#############################
# Bonding
#############################
chkconfig NetworkManager off
echo "alias bond0 bonding" > /etc/modprobe.d/bonding.conf
grep -E '(^BOOTPROTO|^DNS1|^GATEWAY|^IPADDR|^NETMASK|^ONBOOT)' /etc/sysconfig/network-scripts/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-bond0
cat >> /etc/sysconfig/network-scripts/ifcfg-bond0 << EOF
DEVICE=bond0
USERCTL=no
BONDING_OPTS="mode=1 miimon=100"
EOF

for INTERFACE in eth0 eth1; do 
  grep -E '(^DEVICE|^ONBOOT|^HWADDR)' /etc/sysconfig/network-scripts/ifcfg-${INTERFACE} > /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}.tmp
  cat >> /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}.tmp << EOF
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
USERCTL=no
EOF
  mv /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}.tmp /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}
done


#############################
# gruub.conf 
#############################
sed -i.orig 's/^timeout=.*/timeout=1/;s/^hiddenmenu/#hiddenmenu/;s/^\(splashimage=.*\)/#\1/;s/quiet//;s/rhgb//' /boot/grub/grub.conf


#############################
# ntpd
#############################
chkconfig ntpd on
echo -e "server 192.158.100.1\nserver clock.redhat.com" >>/etc/ntp.conf
sed -i.orig "s/^\(SYNC_HWCLOCK\)=no/\1=yes/" /etc/sysconfig/ntpd
ntpdate clock.redhat.com


#############################
# kdump / diskdump
#############################
if rpm -q kexec-tools; then
  chkconfig kdump on
  sed -i 's|.*kernel /.*|& crashkernel=128M|' /boot/grub/grub.conf
  mkdir -pv /var/crash/scripts/
  echo "/bin/logger -p local0.err \"saved a vmcore\"" > /var/crash/scripts/kdump-post.sh
  chmod +x /var/crash/scripts/kdump-post.sh
  cat >> /etc/kdump.conf << EOF
ext3 /dev/mapper/VolGroup00-LogVol00
path /var/core
core_collector makedumpfile -d 31 -c
kdump_post /var/crash/scripts/kdump-post.sh
EOF
fi


#############################
# snmp
#############################
chkconfig snmpd on
sed -i.orig "s/#\(view all\)/\1/;s/\(access  notConfigGroup \"\"      any       noauth    exact \) systemview/\1 all  /;s/^\(syslocation\).*/\1 Test system: $HOSTNAME/;s/^\(syscontact Root\).*/\1 <root@${HOSTNAME}>/" /etc/snmp/snmpd.conf


#############################
# mc
#############################
test -f /usr/share/mc/bin/mc-wrapper.sh && sed -i.orig 's@^\(/usr/bin/mc\)@\1 --nomouse@' /usr/share/mc/bin/mc-wrapper.sh
test -f /usr/libexec/mc/mc-wrapper.sh && sed -i.orig 's@^\(/usr/bin/mc\)@\1 --nomouse@' /usr/libexec/mc/mc-wrapper.sh
