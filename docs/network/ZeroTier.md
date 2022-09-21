# ZeroTier 内网



我们正在逐步用 Tailscale 替换掉 ZeroTier 网络，ZeroTier 将作为 Tailscale 不可用时的备选方案



### **下载客户端**

<https://www.zerotier.com/download/>

## Linux (DEB/RPM)

```bash
curl -s https://install.zerotier.com | sudo bash
```

## macOS

可选择官方的 DMG 安装，或从 Homebrew 进行安装：

```bash
brew cask install zerotier-one
```

## iOS/Android 客户端

⚠️ 手机客户端理论上都是通过 VPN profile 的形式来提供组网支持，因此 Zerotier 与 iOS 上的 Surge、Android 上的 Surfboard、Shadowsocks 等客户端不兼容，也就是说在通过 Zerotier 连接至办公室网络环境的时候无法同时开启 Surge、Surfboard 等翻墙客户端

## 其他平台

请直接访问上方的 Zerotier 官网进行下载

# 加入办公室网络

* ZeroTier ID: `af415e486fcbdb94`
* Name: signcl-office

  zerotier-cli join af415e486fcbdb94

加入后请联系 @Tunghsiao Liu 进行批准

## 加入 Moon 

为了解决 Zerotier 在国内的连通性，我们增加了一个在国内的 moon 节点，可通过下面命令加入：

```bash
zerotier-cli orbit 030686e841 030686e841 # 是两个重复的，此处没有写错
```

加入完后通过下面的命令进行验证：

```bash
$ zerotier-cli listpeers
200 listpeers <ztaddr> <path> <latency> <version> <role>
200 listpeers 030686e841 8.134.9.90/9993;338;798 40 1.8.4 MOON

# 如果 8.134.9.90 后面跟的不是 /9993，说明并非直连
200 listpeers 030686e841 8.134.9.90/29994;6810;6751 53 1.8.4 MOON
```

请勿在公开场合泄漏上述 moon 节点信息

如果连接后发现并没有通过 9993 端口直连，可在路由上对 9993 UDP 协议放行，具体请参考各路由器的防火墙设置方法

### **使用说明**

详细使用详情请参考官方文档

```bash
# 查看状态
zerotier-cli info

# 列出所有 peers
zerotier-cli peers
```


!!! info "操作步骤"
    - Linux或者Mac安装zerotier
    - 加入到zerotier网络
    - zerotier的UI界面勾选刚刚添加的节点

**安装:** [参考官网](https://www.zerotier.com/download/)

```shell
curl -s https://install.zerotier.com | sudo bash
```

节点加入zerotier网络

```shell
root@user:/home/user# zerotier-cli join b15644912ebd050d
200 join OK
```
登陆自己的zerotier帐号，勾选对应机器就可以了