
## **网络模式调整(IB->以太网)**

### **下载驱动程序**

官网地址: https://developer.nvidia.com/networking/infiniband-software

根据自己系统的版本进行选择

连接地址: https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/


![](https://pic.imgdb.cn/item/63ed9eeaf144a010078b5a7f.jpg)


### **安装:**

将我们下载好的驱动程序上传到服务器上，并解压。


1.设置 MLNX_OFED apt-get 存储库


使用以下内容创建名为“/etc/apt/sources.list.d/mlnx_ofed.list”的 apt-get 存储库配置文件

```shell
deb file:/home/openbayes/MLNX_OFED_LINUX-23.07-0.5.1.2-ubuntu22.04-x86_64/DEBS ./
```

2.下载并安装 Mellanox Technologies GPG-KEY

```shell
wget -qO - http://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | sudo apt-key add -
```

3.更新 apt-get 缓存

```shell
sudo apt-get update
```

4.使用 apt-get 工具安装 MLNX_OFED

```shell
apt-get install mlnx-ofed-all
```

5.更新到固件

```shell
apt-get install mlnx-fw-updater
```

5.使用 mlnxofedinstall 脚本安装

```shell
/opt/mlnxofedinstall
```


### **Infiniband卡切换IB/Ethernet模式**


```shell
root@bayes:/home/lixie# mst status
MST modules:
------------
    MST PCI module is not loaded
    MST PCI configuration module loaded

MST devices:
------------
/dev/mst/mt4119_pciconf0         - PCI configuration cycles access.
                                   domain:bus:dev.fn=0000:06:00.0 addr.reg=88 data.reg=92 cr_bar.gw_offset=-1
                                   Chip revision is: 00
```


首先，启动mst 工具，通过 mst工具查看自己的MST devices：/dev/mst/mt4119_pciconf0  （没有mst工具，需要下载安装）


```
root@bayes:/home/lixie# mlxconfig -d /dev/mst/mt4119_pciconf0 query


         LINK_TYPE_P1                                IB(1)
         LINK_TYPE_P2                                IB(1)
```

工作模式修改:

```
Ethernet模式： mlxconfig -d /dev/mst/mt4119_pciconf0 set LINK_TYPE_P1=2
IB模式： mlxconfig -d /dev/mst/mt4119_pciconf0 set LINK_TYPE_P1=1
```

!!! warning "温馨提示"
    调整之后，需要重新启动服务器。
