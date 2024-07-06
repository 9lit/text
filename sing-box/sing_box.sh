#!/bin/sh

if [ -z $(which urlencode) ]; then sudo apt install gridsite-clients; fi

urls=$(urlencode -d $(cat nginx | base64 -d) | xargs | sed 's/\s//g' | sed 's/vless/ vless/g')

for url in ${urls[@]}; do
  url | sed 's/\&\|\?\|:\/\/\|@\|:/ /g'

done