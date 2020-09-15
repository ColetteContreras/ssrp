#!/bin/bash

set -x

systemctl stop ssrp
systemctl disable ssrp

rm -rf /usr/bin/ssrp /etc/systemd/system/ssrp.service /etc/systemd/system/ssrp@.service /etc/ssrp /var/log/ssrp

set -

echo "Success"
