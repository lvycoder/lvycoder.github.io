## **前沿**

由于运维这个行业对于记笔记有一些要求，这个平时我会把我使用的一些常用的东西写在博客中，来总结与归纳。我利用的`mkdocs-material` 来撰写文章，用的他的理由就是：
- 在Mac中很好的兼容，调试起来很方便
- 在编译之后生成的静态页面很好看
- 可以和git结合使用

## **安装与部署（Mac 系统）**
- Python 环境（python3.11）
- mkdocs-material==8.0.0

```
由于python环境我已经预制了，如果没有python环境可以使用
brew install python@3.11
pip3 install mkdocs-material==8.0.0
```

**报错:**

```
mkdocs serve  启动mkdocs 报错
ERROR    -  Config value 'plugins': The "minify" plugin is not installed
Aborted with 1 Configuration Errors!
```

**解决:**

这是因为配置文件中使用到了minify这个插件，但是这里没有安装，需要通过`pip3 install mkdocs-minify-plugin`进行安装。


## **文章参考**
- https://squidfunk.github.io/mkdocs-material/
