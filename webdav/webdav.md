# webdav
获取 webdav 服务器上的视频文件, 转换为 m3u 文件输出到本地

## 前置条件
### 安装 python
### 下载 python 库

~~~
pip install webdav4
~~~

## 填入变量
path: webdav 服务器地址
username = "用户名"
password = "密码"
dirpath = '根目录'
localpath = r'本地输出地址'

## 执行文件,等待完成

~~~
python webdav.py
~~~
