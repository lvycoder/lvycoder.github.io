# ZeroTier 内网

## **背景**
随着互联网的普及，可用的公网 IPv4 地址越来越少，现在的运营商基本不给家用宽带分配公网 IP 了。如果你想通过外网访问到内网的资源，目前只能采用内网穿透的软件来实现。常见的内网穿透如: frp 这样的工具，但是如果要使用这样的工具需要有一台具备公网地址的服务器才可以。

做为一名优秀的技术人员，当然是能白嫖就白嫖，下面主要来介绍一款不需要公网的P2P工具ZeroTier
![](https://pic1.imgdb.cn/item/63355b9316f2c2beb149496a.jpg)

## **原理**

ZeroTier 这一类 P2P VPN 是在互联网的基础上将自己的所有设备组成一个私有的网络，可以理解为互联网连接的局域网。

大白话就是一堆服务器安装上这个软件就组建了一个内网，大家通过这个特定网段内网可以互相访问。


!!! info "优点"
    - 内网穿透工具（免费）
    - ZeroTier 支持 Windows、macOS、Linux 三大主流平台，iOS、Android 两大移动平台

我们正在逐步用 Tailscale 替换掉 ZeroTier 网络，ZeroTier 将作为 Tailscale 不可用时的备选方案


官网地址: https://www.zerotier.com/

下载客户端: https://www.zerotier.com/download/



## **Linux (DEB/RPM)**

```bash
curl -s https://install.zerotier.com | sudo bash
```

## **macOS**

可选择官方的 DMG 安装，或从 Homebrew 进行安装：

```bash
brew cask install zerotier-one
```

!!! warning "温馨提示"
    我这边主要是以使用linux和mac为主，其他平台请直接访问上方的 Zerotier 官网进行下载



## **安装**

!!! info "操作步骤"
    - Linux或者Mac安装zerotier
    - 加入到zerotier网络
    - zerotier的UI界面勾选刚刚添加的节点

**安装:** [参考官网](https://www.zerotier.com/download/)

```shell
curl -s https://install.zerotier.com | sudo bash
```

节点加入zerotier网络，加入网络之前需要提前创建这个网络

```shell
root@user:/home/user# zerotier-cli join b15644912ebd050d
200 join OK
```

![](https://pic1.imgdb.cn/item/63355da416f2c2beb14ba07e.jpg)
登陆自己的zerotier帐号，勾选允许对应机器就可以了，这里推荐使用github帐号。
