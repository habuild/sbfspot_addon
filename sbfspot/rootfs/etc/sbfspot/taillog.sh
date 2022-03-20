#!/usr/bin/with-contenv bashio

cd /

tail -fn1 /data/sbfspot/log/* > /dev/stdout >> /proc/1/fd/1
