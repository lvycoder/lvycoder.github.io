## 阿勰的博客
  Hello，大家好！
    我叫阿勰，北漂一族。在弄这个网站的初衷主要是为了记录自己工作和生活的内容。
    大家可以点击进入[《Kubernetes 进阶训练营》](https://lvycoder.github.io/site/)以后也将持续更新～

  - 主要记录工作以及生活内容
  - 把工作和生活的事情列清楚，为了以后做复盘
  - 做运维需要记录一些遇到的问题用来总结经验


<!-- |微信（勰哥本人）|公众号|
|:----:|:----:|
|<img src="https://github.com/barry-boy/barry-boy.github.io/blob/main/png/weixin.pic.jpg" width="115">|<img src="https://github.com/barry-boy/barry-boy.github.io/blob/main/png/qrcode_for_gh_1330095f1c05_860.jpg" width="125"> -->

## 博客离线：Mac 部署

由于运维这个行业对于记笔记有一些要求，这个平时我会把我使用的一些常用的东西写在博客中，来总结与归纳。我利用的mkdocs-material 来撰写文章，用的他的理由就是：

在Mac中很好的兼容，调试起来很方便
在编译之后生成的静态页面很好看
可以和git结合使用

## 安装与部署（Mac 系统）
- Python 环境（python3.11）
- mkdocs-material==8.0.0

由于python环境我已经预制了，如果没有python环境可以使用
```
brew install python@3.11
pip3 install mkdocs-material==8.0.0
```

## 启动测试

```
git clone https://github.com/lvycoder/lvycoder.github.io.git
cd barry-boy.github.io
mkdocs serve
```

浏览器测试：http://127.0.0.1:8000


## 文章参考

- https://squidfunk.github.io/mkdocs-material/
