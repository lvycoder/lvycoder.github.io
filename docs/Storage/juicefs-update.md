## **前言**

我自己有一个demo环境，上面安装了一个juicefs,最近正式版发布了，所以要对线上环境升级。JuiceFS 的客户端只有一个二进制文件，一般情况下升级时只需要用新版本软件替换旧版即可。


 1. 首先要对 values 中`juicefs-csi-driver`镜像版本升级`v0.22.0`
 2. 升级所有客户端软件到 v1.1 版本
 3. 拒绝 v1.1 之前的版本再次连接：`juicefs config META-URL --min-client-version 1.1.0-A`
 4. 重启服务
 5. 确保所有在线客户端版本都在 v1.1 或以上：`juicefs status META-URL | grep -w Version`
 6. 启用新特性，具体参见目录用量统计和目录配额


!!! warning "温馨提示"
    JuiceFS 在 v1.1（具体而言，是 v1.1.0-beta2）版本中新增了目录用量统计和目录配额两个功能，且目录配额依赖于用量统计。这两项功能在旧版本客户端中没有，当它们被开启的情况下使用旧客户端写入会导致统计数值出现较大偏差。在升级到 v1.1 时，若您不打算启用这两项新功能，可以直接使用新版本客户端替换升级，无需额外操作。若您打算使用，则建议您在升级前了解以下内容。


默认配置(目前这两项功能的默认配置为：)

新创建的文件系统，会自动启用
已有的文件系统，默认均不启用

- 目录用量统计可以通过 juicefs config 命令单独开启
- 设置目录配额时，用量统计会自动开启

可以直接升级：
```
# 默认安装到 /usr/local/bin
curl -sSL https://d.juicefs.com/install | sh -
```


### **参考文章**

- https://juicefs.com/docs/zh/community/release_notes#juicefs-v10
  