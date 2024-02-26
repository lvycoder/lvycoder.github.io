## **系统安装**
正所谓不会装系统的运维就不是好运维的理念，下面介绍一下ubuntu系统安装

!!! info "准备工作"
    - 步骤一: 下载iso镜像
        - 下载地址: https://mirrors.aliyun.com/ubuntu-releases/
    - 步骤二: 制作系统盘
        - 可以参考文章中Mac制作系统盘这篇文章
    - 步骤三: 装就完事了

1.1. 选择语言
![第一步](https://pic.imgdb.cn/item/632d192516f2c2beb1185a77.png)

1.2. 选择键盘（本步骤直接默认按回车即可。）

![第二步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a80.png)

1.3. 配置网络（一般情况会直接跳过这一步）

![第三步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a8b.png)

1.4. 选择代理（默认回车跳过）

![第四步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a94.png)

1.5. 配置镜像源（跳过），配置网络的步骤也可以跳过之后从系统中配置也是可以的。

1.6. 选择磁盘（这个步骤比较关键）

![第五步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a9e.png)

选择磁盘这一步需要注意，需要所有磁盘空间分给根分区
![第五步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a6c.png)

![第五步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a7d.png)


1.7. 用户信息

![第六步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a90.png)


1.8. openssh server 切记要选择上 (`切记`)

![第七步](https://pic.imgdb.cn/item/632d193416f2c2beb1186aa0.png)