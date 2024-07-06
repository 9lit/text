#!/bin/sh

sudo apt update && sudo apt install gridsite-clients

$urls=$(urlencode -d $(cat nginx | base64 -d) | xargs | sed 's/\s//g' | sed 's/vless/ vless/g' | xargs -n1)
