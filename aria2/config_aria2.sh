#!/bin/bash

# 设置全局变量
## 基础路径配置
URL="http://text.1210923.xyz/aria2"
GITHUB="https://github.com/9lit/aria2.conf.git"

ARIA2_CONFIG_PATH="/etc/aria2"
ARIA2_CONFIG="${ARIA2_CONFIG_PATH}/aria2.conf"

NGINX_CONFIG_PATH="/etc/nginx"
NGINX_CONFIG_FILE="${NGINX_CONFIG_PATH}/sites-enabled/aria2"
## nginx 代理端口
NGINX_PROXY_PORT=2053


# 更新软件源
sudo apt update -y

# 下载 aria2
if [ -z "$(sudo which aria2c)" ]; then sudo apt install aria2 -y; fi


# 创建配置文件
## 向 github 中获取 aria2 配置文件
if [ -z "$(sudo which git)" ]; then sudo apt install git -y; fi
sudo rm -rf $ARIA2_CONFIG_PATH && sudo git clone "$GITHUB" $ARIA2_CONFIG_PATH
## 创建保存文件夹 和 会话文件
sudo mkdir "${ARIA2_CONFIG_PATH}/download" && sudo touch "${ARIA2_CONFIG_PATH}/aria2.session" 
## 赋予可执行权限
cd $ARIA2_CONFIG_PATH && sudo chmod +x delete.sh scrape.sh upload.sh


#使用 systemctl 管理 aria2 服务
service="[Unit] \nDescription=Aria2 Service \nAfter=network.target \n\n[Service] \nExecStart=$(sudo which aria2c) --conf-path=${ARIA2_CONFIG_PATH}/aria2.conf \n\n[Install] \nWantedBy=default.target"
## 将配置写入 aria2.service 并刷新 systemctl服务
sudo bash -c "echo -e '$service' > /usr/lib/systemd/system/aria2.service" && sudo systemctl daemon-reload

# 获取监听端口
RPC_PORT=$(cat ${ARIA2_CONFIG} | grep -oP "rpc-listen-port=\d+" | grep -oP "\d+")
BT_PORT=$(cat ${ARIA2_CONFIG} | grep -oP "listen-port=\d+" | grep -oP "\d+")
DHT_PORT=$(cat ${ARIA2_CONFIG} | grep -oP "dht-listen-port=\d+" | grep -oP "\d+")


# 使用 nginx 进行代理 aria rpc 服务
# read -t 5 -ep "是否使用 nginx 代理 aria2(y/N)" flag
flag=$1
if [ "${flag,,}" = nginx ]; then
  ## 对 aria2 进行反代理
  if [ -z "$(sudo which nginx)" ]; then sudo apt install nginx -y; fi
  ## 设置 nginx 代理 配置
  ### 删除之前的配置 nginx 配置
  sudo rm -rf $NGINX_CONFIG_FILE
  ### 设置 nginx 代理 配置
  sudo bash -c "curl ${URL}/nginx-config > ${NGINX_CONFIG_FILE}" && sudo ln ${NGINX_CONFIG_FILE} "${NGINX_CONFIG_PATH}/sites-enabled/aria2"
  ## 关闭 原配置文件中的 rpc 远程访问权限
  sudo sed -i "s/rpc-allow-origin-all=true/rpc-allow-origin-all=false/g" ${ARIA2_CONFIG} && sudo sed -i "s/rpc-listen-all=true/rpc-listen-all=false/g" ${ARIA2_CONFIG}
  ## 重启 nginx 服务
  sudo systemctl restart nginx
else
  sudo sed -i "s/rpc-allow-origin-all=false/rpc-allow-origin-all=true/g" ${ARIA2_CONFIG} && sudo sed -i "s/rpc-listen-all=false/rpc-listen-all=true/g" ${ARIA2_CONFIG}
fi

# 开启 ufw 端口
if [ -n "$(sudo which ufw)" ]; then 
  ## 放行 DHT 和 UDP tracker 监听端口
  sudo ufw allow ${BT_PORT}/tcp && sudo ufw allow ${DHT_PORT}/udp
  if [ "${flag,,}" = nginx ]; then 
    # 开放 nginx 代理端口
    sudo ufw allow ${NGINX_PROXY_PORT}/tcp && sudo ufw deny ${RPC_PORT}/tcp
  else 
    # 开放 本地端口
    sudo ufw allow ${RPC_PORT}/tcp && sudo ufw deny ${NGINX_PROXY_PORT}/tcp
  fi
fi


#重启 aria2 服务
sudo systemctl restart aria2
