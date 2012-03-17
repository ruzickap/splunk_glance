#!/bin/bash

SPLUNK_URL="http://192.168.122.1/~pruzicka/ks/splunk-4.3.1-119532-linux-2.6-x86_64.rpm"
SPLUNK_RPM=`basename $SPLUNK_URL`

wget -P /tmp/ $SPLUNK_URL
if [ ! -f /tmp/$SPLUNK_RPM ]; then
  echo -e "Can not find the splunk RPM in /tmp/$SPLUNK_RPM !\n"
  echo -e "Please check if the \"/tmp/$SPLUNK_RPM\" file was downloaded successfully from: $SPLUNK_URL\n"
  exit 1
fi

## Splunk
rpm -Uvh /tmp/$SPLUNK_RPM
#Enable SSL
#sed -i.orig 's/^enableSplunkWebSSL = false/enableSplunkWebSSL = true/' /opt/splunk/etc/system/default/web.conf
sed -i.orig 's/^\(enableSplunkWebSSL\) = false/\1 = true/' /opt/splunk/etc/system/default/web.conf
/opt/splunk/bin/splunk start --accept-license
/opt/splunk/bin/splunk enable boot-start

PASSWORD="xxxx"
/opt/splunk/bin/splunk edit user admin -password $PASSWORD -role admin -auth admin:changeme
/opt/splunk/bin/splunk add tcp 514 -sourcetype syslog -auth admin:$PASSWORD
#Disable password change request
touch /opt/splunk/etc/.ui_login
