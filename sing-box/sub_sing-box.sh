#!/bin/sh

# 设置变量
HOME=$(dirname "$(realpath -es "$0")")
TEMPLATE_FILE=http://text.1210923.xyz/sing-box/template.json
CONFIG_FILE=/home/kuma/singbox_config.json
SUB_FILE=https://sub.tgzdyz2.xyz/sub
GITHUB_PATH=$1

# GITHUB_PATH 不为空时 ,检查本地项目文件夹是否存在
if [ -z $GITHUB_PATH ]; then upload_flag=1; else
  succeed="请确保此文件夹是 github 的本地项目, 且具有推送权限" && fail="指定文件夹不存在,请检查后重新执行"
  if [ -d $GITHUB_PATH ]; then upload_flag=0 && echo $succeed ; else echo $fail && exit 0; fi
fi

# 检测依赖是否存在， 不存在则进行下载
if [ -z $(which urlencode) ] || [ -z $(which jq) ]; then sudo apt update; fi
if [ -z $(which urlencode) ] ; then sudo apt install gridsite-clients; fi
if [ -z $(which jq) ]; then sudo apt install jq; fi


function CutUrl() {
  urls=($(echo $1 | sed 's/:\/\/\|@\|:/ /g' ))
  # 如果 数组长度小于4， 则跳过本次循环
  if [ ${#urls[@]} -lt 4 ]; then return 1 
  # 如果协议不是 vless 则跳过本次循环
  elif [ ${urls[0]} != 'vless' ]; then return 2
  else return 0; fi
}

function CutParams() {
  params_string=$(echo $param | sed 's/\&/ /g')
  for param_string in ${params_string[@]}; do
    # echo $param_string
    value=${param_string#*\=}; key=${param_string%%\=*}
    params[$key]=$value
  done
}

function GetConfig() {

  config_string='[{
    "tag": "'$tag'",
    "server": "'${urls[2]}'",
    "server_port": '${urls[3]}',
    "uuid": "'${urls[1]}'",
    "type": "'${urls[0]}'",
    "packet_encoding": "xudp",
    "tls":{
      "enabled": true,
      "insecure": false,
      "server_name": "'${params["sni"]}'",
      "utls": {
        "enabled": true,
        "fingerprint": "'${params["fp"]}'"}
    },
    "transport":{
      "type": "'${params["type"]}'",
      "path": "'${params["path"]}'",
      "headers": {"Host": "'${params["host"]}'"}
    }
  }]'

}

function AddConfig() {
  # 添加节点
  add_selector_outbounds=$(echo "$config" | jq '.outbounds[0].outbounds += ["'$tag'"]')
  add_outbounds=$(echo "$add_selector_outbounds" | jq ".outbounds += ${config_string}")
  config="$add_outbounds"
}

function ModRepeatTag() {
  # 修改重复标签
  if [[ "${tags[@]}" =~ $tag ]]; then tag="${tag}-${i}"; fi
  tags[${#tags[*]}]=$tag
}

function Contextencode() {
  # 订阅解码
  sub_context=$(curl $SUB_FILE)
  # base64 解码 和 url 解码 | 
  context_base64=$(echo $sub_context | base64 -d) && context_urlencode=$(urlencode -d "$context_base64")
  # 删除多余的空格, 并将换行符转换为空格
  links=$(echo "$context_urlencode" | sed 's/\s//g' | xargs)
}

function GetSubParam() { 
  url=${link%%\?*} && param=${link#*\?*}; tag=${param#*\#} && param=${param%*\#*} 
}

function UploadGithub() {
  # 将输出的 sing-box 配置文件上传到 github 仓库中
  cd $GITHUB_PATH && git pull
  # 将已生成的配置, 输入到 config.json 文件中
  echo "$config" > $GITHUB_PATH/sing-box/config.json
  # 更新 GitHub
  git add . && git commit -am "更新 sing-box 配置文件" && git push
}

config=$(curl $TEMPLATE_FILE) && Contextencode
declare -a tags && i=0
for link in ${links[@]}; do
  # param=$(echo $link | cut -d "?" -f 2)
  GetSubParam && CutUrl $url 
  if [ $? != 0 ]; then continue; fi
  ((i++)) && ModRepeatTag
  declare -A params && CutParams $param
  GetConfig && AddConfig
done

# 输出配置文件
if [ $upload_flag -eq 0 ]; then 
  UploadGithub
else 
  echo "$config" > $CONFIG_FILE
fi
