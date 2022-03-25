#!/usr/bin/with-contenv bashio

cd /

lognow=$(date +%Y%m%d)

sleep 45

# set tail to log out to HA log
echo '[SBFspot Upload Log Latest]'
tail -n1 /data/sbfspot/log/SBFspotUpload$lognow.log >> /proc/1/fd/1

#busybox command for minus 1 day
#date +%Y%m%d -d @$(($(date +%s)-86400))

# remove log files older than 3 days
find /data/sbfspot/log -mtime +3 -exec rm {} \;
