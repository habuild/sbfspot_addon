#!/usr/bin/with-contenv bashio

cd /

# create placeholder to avoid delay on real log
echo [$(date)] INFO: SBFspotUpload Logging started > /data/sbfspot/log/fake.log

# set tail to log out to HA log
echo 'logging commenced'
tail -n1 /data/sbfspot/log/* >> /proc/1/fd/1
