#!/bin/bash

if [ -z "$(sudo which aria2)" ]; then sudo apt update -y && sudo apt install aria2 -y; fi

# 配置 对 aria2 进行配置
## 创建 aria2 配置文件目录
sudo mkdir /etc/aria2/ 
## 创建 aria2 下载目录
sudo mkdir /etc/aria2/download/

if [ -z "$(sudo which git)" ]; then sudo apt update -y && sudo apt install git -y; fi
## 拉取配置文件
sudo git clone git@github.com:xiongJum/aria2.conf.git /etc/aria2

sudo chmod +x delete.sh scrape.sh upload.sh

echo "是否使用 nginx 代理 aria2(y/N)"
read -r flag
if [ "${flag,,}" = y ]; then 0; else echo "脚本退出, 不使用nginx 进行反代理" exit 0; fi

# 对 aria2 进行反代理
if [ -z "$(sudo which nginx)" ]; then sudo apt update -y && sudo apt install nginx -y; fi

# 设置 nginx 并重启
sudo cp /etc/aria2/nginx-aria2-config /etc/nginx/sites-available/aria2
sudo ln /etc/nginx/sites-available/aria2 /etc/nginx/sites-enabled/aria2
sudo systemctl restart nginx

# 关闭 原配置文件中的 rpc 远程访问权限
sed -i "/rpc-allow-origin-all=true/rpc-allow-origin-all=false" /etc/aria2/aria2.conf
sed -i "/^rpc-listen-all=true/rpc-listen-all=flase" /etc/aria2/aria2.conf
sudo systemctl restart aria2
