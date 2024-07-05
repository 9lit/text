#!/bin/sh

apnic_ip=$(curl http://ftp.apnic.net/stats/apnic/delegated-apnic-latest)
cn_ipv4=$(echo "$apnic_ip" | awk -F '|' '/CN/&&/ipv4/ {print "\"" $4 "/" 32-log($5)/log(2) "\"" ","}')

gfw='{"rules": [{"domain": ['${cn_ipv4::-1}']}],"version": 1}'

if [ -z "$(which jq)" ]; then sudo apt update -y && sudo apt install aria2 -y; fi
echo "$gfw" | jq . > ./sing-box/apnic_cn_ipv4.json