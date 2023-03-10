# 服务器BMC（带外）

## **简介**
服务器除了装linux，windows系统外，相应还有一个可通过网线（服务器默认带外地址--可改）连接具体厂商服务器的BMC（Baseboard Management Controller，基板管理控制器）

智能平台管理接口 (IPMI) 是一种开放标准的硬件管理接口规格，定义了嵌入式管理子系统进行通信的特定方法。IPMI 信息通过基板管理控制器 (BMC)（位于 IPMI 规格的硬件组件上）进行交流。使用低级硬件智能管理而不使用操作系统进行管理，具有两个主要优点： 首先，此配置允许进行带外服务器管理；其次，操作系统不必负担传输系统状态数据的任务。一般统称Mgmt管理网口，华为的白皮书叫iBMC，戴尔叫idrac，其实都是兼容ipmi协议的网口而已~

BMC系统独立，管理硬件（cpu，风扇等信息），打开控制台,来远程管理我们的服务器，让运维的同学少跑一万次的机房～

## **实践**

下面介绍一下我这边曙光GPU服务器的带外管理。

```shell
$ ssh -L 3443:192.168.2.x:443 routerx.c1
```

这个我们是用另一台机器做跳板才能登陆，所以需要执行以上命令～


自带浏览访问: https://127.0.0.1:3443

- 需要输入帐号密码

<kbd>![](https://pic1.imgdb.cn/item/634982f316f2c2beb1dcca28.jpg)</kbd>


<kbd>![](https://pic1.imgdb.cn/item/634984f716f2c2beb1e1a543.jpg)</kbd>

通过以上的方式,就可以对服务器进行重启,关机,重装系统等操作~

## **附件**

!!! info "Linux配置"
    ```shell
    apt-get install ipmitool
    ipmitool lan print              # 查看BMC的地址
    ipmitool lan set 1 ipsrc static
    ipmitool lan set 1 ipaddr 192.168.2.21
    ipmitool lan set 1 netmask 255.255.255.0
    ipmitool lan set 1 defgw ipaddr 192.168.2.1
    ```



