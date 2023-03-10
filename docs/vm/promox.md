## **Proxmox**
Proxmox VE 是一个完整的、开源的企业虚拟化服务器管理平台。它将 KVM 管理程序和 Linux 容器 (LXC)、软件定义的存储和网络功能紧密集成在一个平台上。借助基于 Web 的集成用户界面，您可以轻松管理 VM 和容器、集群的高可用性或集成的灾难恢复工具。
![](https://pic1.imgdb.cn/item/633aea6316f2c2beb16a04d4.jpg)


**优势:**

- 可以直接使用UI界面对虚拟化已经操作
- 既可以虚拟windows机器，也可以虚拟Linux机器
- 使用简单，上手较快


## **部署Pve**

### **制作系统盘**

工具分享: [rufus工具下载链接](https://www.aliyundrive.com/s/Qp5sC3YrKre)

如果网盘失效可以访问官网: https://rufus.ie/zh/ 进行下载


image 分享: https://www.proxmox.com/en/downloads

!!! warning "温馨提示"
    这个制作系统盘一定要选择dd的方式

![](https://pic1.imgdb.cn/item/633aed6916f2c2beb170c6d3.jpg)

到这里系统盘就搞定了，那么就可以安装Pve这个系统了。 其实他的操作系统从下图就能看出是一个debian

```shell
root@node1:~# cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

那么接下来就是安装系统，如果需要配置raid就可以先配置一下，这里就不过多的解释raid的概念了。

安装系统其实就是普通的操作流程，这里就略过～

如果实在不懂可以参考：https://www.jianshu.com/p/a2ad1aed6a92 的安装流程，基本就是这样


### **PVE 系统初始化**


#### **更换国内源:**

!!! info "清华源"
    ```
    # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

    deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

    deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
    # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
    ```

#### **install package:**(非必需)
```shell
ifupdown2,openvswitch-switch,vim 
apt update
apt install ifupdown2 openvswitch-switch -y
```

### **存储**

分区格式化，挂载
```shell
fdisk /dev/sdb
mke2fs -t ext4 /dev/sdb1
mount /dev/sdb1 /mnt/pve/node5_sdb
以上这里是临时挂载的，需要将其写入/etc/fstab

```


!!! error "格式化报错"
    ```
    root@node18:~# mke2fs -t ext4 /dev/sdb1
    mke2fs 1.44.5 (15-Dec-2018)
    /dev/sdb1 is apparently in use by the system; will not make a filesystem here!
    ```
    解决方法

    ```
    root@node18:~# dmsetup remove_all
    root@node18:~# mke2fs -t ext4 /dev/sdb1
    mke2fs 1.44.5 (15-Dec-2018)
    Creating filesystem with 244055808 4k blocks and 61014016 inodes
    Filesystem UUID: dd408faf-92ff-467a-baf4-58d653ec3e40
    Superblock backups stored on blocks:
            32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
            4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
            102400000, 214990848

    Allocating group tables: done
    Writing inode tables: done
    Creating journal (262144 blocks): done
    Writing superblocks and filesystem accounting information: done
    ```

#### **UI界面添加磁盘**

![](https://pic1.imgdb.cn/item/633af27516f2c2beb17b0160.jpg)

根据实际情况填写，这里截图不准确

![](https://pic1.imgdb.cn/item/633af2a716f2c2beb17b634c.jpg)

添加以上信息，可以看到硬盘已经挂载上

![](https://pic1.imgdb.cn/item/633af2d716f2c2beb17bc736.jpg)

### **网络**

配置网络

![](https://pic1.imgdb.cn/item/63402c2916f2c2beb11f045b.jpg)

配置组建成集群的网卡
![](https://pic1.imgdb.cn/item/63402c6316f2c2beb11f6e58.jpg)


命令行操作或者应用配置

```shell
cd /etc/network/
mv interfaces.new interfaces
reboot
```

激活网络
![](https://pic1.imgdb.cn/item/63402cc216f2c2beb1201c13.jpg)

![](https://pic1.imgdb.cn/item/63402ce116f2c2beb12059a5.jpg)


### **集群管理:**

管理命令

```shell
# 停止虚拟机
qm stop <vmid> [OPTIONS]

# 删除
qm destroy <vmid> [OPTIONS]

# 解锁
qm unlink <vmid> --idlist <string> [OPTIONS]
```



驱逐故障机器 ：
```
cd /etc/pve/nodes																					# 删除故障节点node文件
rm -rf /etc/pve/nodes/pve2    	# 改成故障节点对应路径
root@node17:/etc/pve/nodes# pvecm delnode node12          # 登录集群中任意正常节点，执行如下指令进行驱逐操作
```
