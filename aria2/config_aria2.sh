#!/bin/bash

if [ -z "$(sudo which aria2)" ]; then sudo apt update -y && sudo apt install aria2 -y; fi

# 配置 对 aria2 进行配置

if [ -z "$(sudo which git)" ]; then sudo apt update -y && sudo apt install git -y; fi
## 拉取配置文件
sudo rm -rf /etc/aria2/ && sudo git clone https://github.com/xiongJum/aria2.conf.git /etc/aria2

## 赋予可执行权限
cd /etc/aria2 && sudo chmod +x delete.sh scrape.sh upload.sh

## 使用 systemctl 管理服务

service="[Unit]
> Description=Aria2 Service
> After=network.target
> 
> [Service]
> ExecStart=/usr/bin/aria2c --conf-path=/etc/aria2/aria2.conf
> 
> [Install]
> WantedBy=default.target"

sudo bash -c "echo $service > /usr/lib/systemd/system/aria2.service" && sudo systemctl daemon-reload

# 使用 nginx 进行代理 aria rpc 服务
read -t 5 -ep "是否使用 nginx 代理 aria2(y/N)" flag && if [ "${flag,,}" = y ]; then echo “使用 nginx 对 nginx 进行反代理”; else echo "脚本退出, 不使用nginx 进行反代理" exit 0; fi

## 对 aria2 进行反代理
if [ -z "$(sudo which nginx)" ]; then sudo apt update -y && sudo apt install nginx -y; fi

## 设置 nginx 代理 配置
sudo cp /etc/aria2/nginx-aria2-config /etc/nginx/sites-available/aria2 && sudo ln /etc/nginx/sites-available/aria2 /etc/nginx/sites-enabled/aria2

## 关闭 原配置文件中的 rpc 远程访问权限
sudo sed -i "/rpc-allow-origin-all=true/rpc-allow-origin-all=false" /etc/aria2/aria2.conf && sudo sed -i "/^rpc-listen-all=true/rpc-listen-all=flase" /etc/aria2/aria2.conf

## 重启 aria2 和 nginx 服务
sudo systemctl restart aria2 nginx
