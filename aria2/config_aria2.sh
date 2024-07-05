#!/bin/bash

# 更新软件源
sudo apt update -y

# 下载 aria2 
if [ -z "$(sudo which aria2c)" ]; then sudo apt install aria2 -y; fi


# 创建配置文件
## 向 github 中获取 aria2 配置文件
if [ -z "$(sudo which git)" ]; then sudo apt install git -y; fi
sudo rm -rf /etc/aria2/ && sudo git clone https://github.com/xiongJum/aria2.conf.git /etc/aria2
## 创建保存文件夹 和 会话文件
sudo mkdir /etc/aria2/download/ && sudo touch /etc/aria2/aria2.session 
## 赋予可执行权限
cd /etc/aria2 && sudo chmod +x delete.sh scrape.sh upload.sh


#使用 systemctl 管理 aria2 服务
service="[Unit] \nDescription=Aria2 Service \nAfter=network.target \n\n[Service] \nExecStart=/usr/bin/aria2c --conf-path=/etc/aria2/aria2.conf \n\n[Install] \nWantedBy=default.target"
## 将配置写入 aria2.service 并刷新 systemctl服务
sudo bash -c "echo -e '$service' > /usr/lib/systemd/system/aria2.service" && sudo systemctl daemon-reload


# 使用 nginx 进行代理 aria rpc 服务
read -t 5 -ep "是否使用 nginx 代理 aria2(y/N)" flag
if [ "${flag,,}" = y ]; then
  ## 对 aria2 进行反代理
  if [ -z "$(sudo which nginx)" ]; then sudo apt install nginx -y; fi
  ## 设置 nginx 代理 配置
  sudo cp /etc/aria2/nginx-aria2-config /etc/nginx/sites-available/aria2 && sudo ln /etc/nginx/sites-available/aria2 /etc/nginx/sites-enabled/aria2
  ## 关闭 原配置文件中的 rpc 远程访问权限
  sudo sed -i "s/rpc-allow-origin-all=true/rpc-allow-origin-all=false/g" /etc/aria2/aria2.conf && sudo sed -i "s/rpc-listen-all=true/rpc-listen-all=false/g" /etc/aria2/aria2.conf
  ## 重启 nginx 服务
  sudo systemctl restart nginx
else
  sudo sed -i "s/rpc-allow-origin-all=false/rpc-allow-origin-all=true/g" /etc/aria2/aria2.conf && sudo sed -i "s/rpc-listen-all=false/rpc-listen-all=true/g" /etc/aria2/aria2.conf
  echo "脚本退出, 不使用nginx 进行反代理" exit 0; fi

# 开启 ufw 端口
if [ -n "$(sudo which ufw)" ]; then 
  ## 放行 DHT 和 UDP tracker 监听端口
  sudo ufw allow 51413/tcp && sudo ufw allow 51413/udp
  if [ "${flag,,}" = y ]; then 
    # 开放 nginx 代理端口
    sudo ufw allow 2053/tcp && sudo ufw deny 6800/tcp
  else 
    # 开放 本地端口
    sudo ufw allow 6800/tcp && sudo ufw deny 2053/tcp
  fi
fi


#重启 aria2 服务
sudo systemctl restart aria2
