#!/bin/sh

echo "[$(date)] Launching Core Engine (Xray)..."
/usr/local/bin/xray run -c /etc/xray.json 2>&1 &

echo "[$(date)] Testing interior socket availability..."
while ! nc -z 127.0.0.1 10000; do 
    sleep 0.2
done

echo "[$(date)] Core engine active. Transferring control to OpenResty..."
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
