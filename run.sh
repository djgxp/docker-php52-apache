#!/bin/sh
set -e
/bin/bash /tmp/set_root_pw.sh
/etc/init.d/ssh start
exec /usr/sbin/apache2ctl -D FOREGROUND