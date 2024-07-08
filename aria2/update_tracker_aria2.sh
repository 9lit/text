#!/bin/bash

ARIA2_CONFIG=/etc/aria2/aria2.conf
TRACKER=https://cf.trackerslist.com/all_aria2.txt

if [ $UID -ne 0 ]; then
    sudo bash $0
    exit 0
fi
sed -i "s|bt-tracker=.*|bt-tracker=$(curl $TRACKER)|g" "${ARIA2_CONFIG}"
systemctl restart aria2.service