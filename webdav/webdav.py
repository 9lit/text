import os, re
from urllib import parse
from webdav4.fsspec import WebdavFileSystem
"""
使用 webdav4 库, 遍历服务器视频文件, 并在本地输出 m3u 文件
"""

def write(out_path, content):
    """
    out_path: 本地输出文件路径
    content: 本地输出文件内容
        #EXTM3U
        #EXTINF:-1 ,title
        webdav 播放路径 
    """
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
def get_ext_filename(resource_path:str, ext=True):
    """ 获取 文件扩展名 或者 文件名
    resource_path: 从 webdav 服务器获取的资源路径
    ext: 布尔值, 返回 文件名称还是 文件扩展名
    """
    basename = os.path.basename(resource_path)
    filename, ext = os.path.splitext(basename)
    return ext if ext else filename

def cat_title(nfo_path:str):
    """ 从视频的 nfo 文件中的 <title> 获取集标题名称
    nfo_path: nfo 路径
    """
    with fs.open(path=nfo_path, mode="r", encoding='utf-8') as f:
        return re.findall(r"<title>(.*?.*.*?)<\/title>", f.read())[0]
    
def get_extend(resource_path:str, extension:str=".nfo"):
    """获取扩展文件"""
    return os.path.splitext(resource_path)[0] + extension

def get_title(resource_path:str):
    """ 获取集视频标题, 如果没有获取到,则返回视频文件名称"""
    extend = get_extend(resource_path)
    filename = get_ext_filename(resource_path, ext=False)
    if fs.exists(extend):
        title = cat_title(extend)
        return title if title else filename
    else:
        return filename
def download_subtitles(resource_path, extension):
    """下载字幕文件"""
    subtitles = get_extend(resource_path, extension)
    if fs.exists(subtitles):
        fs.download_file(subtitles, get_local_path(resource_path, extension=extension))
    
def get_url(resource_path:str):
    """ 获取视频文件的 webdav 地址 """
    url = path + '/' + parse.quote(resource_path)
    return  re.sub(r"\/dav\/", '/d/', url)

def get_local_path(resource_path:str, slice:int=-3, extension:str=".m3u"):
    """获取输出的文件的本地地址 
    slice: 电视剧名称在切片后路劲的位置, 电视剧一般在 -3, 电影在 -2
    """
    split = resource_path.split("/")
    filename = re.sub(r"\..*", extension, split[-1])
    return os.path.join(localpath, split[slice], filename)

def work_files(resource_path):
    """处理文件"""
    extension = get_ext_filename(resource_path)
    if extension in ['.mp4', '.mkv']:
        content = "#EXTM3U\n#EXTINF:-1 ,%s\n%s" % (get_title(resource_path), get_url(resource_path))
        write(get_local_path(resource_path), content=content)
        print(content)
    elif extension == '.ass':
        download_subtitles(resource_path, extension)
        print(resource_path)

def traverse_directory(collection:list):
    """ 对 webdav 递归遍历
    """
    for resource_path in collection:
        try:
            if fs.isdir(resource_path): traverse_directory(fs.ls(resource_path, detail=False))
            else: work_files(resource_path)
        except FileNotFoundError:
            continue

def sync():

    os.system(f"rclone sync {localpath} {remotepath}")

def main():
    """主程序"""
    global fs
    fs = WebdavFileSystem(path, auth=(username, password))
    dir = fs.ls(dirpath, detail=False)
    traverse_directory(dir)
    
if __name__ == "__main__":

    path = "webdav 服务器地址"
    username = "用户名"
    password = "密码"
    dirpath = '根目录'
    localpath = '本地输出地址'
    remotepath = 'rclone 输入地址'
    main(); sync()

