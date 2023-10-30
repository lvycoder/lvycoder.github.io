
## **系统安装**
正所谓不会装系统的运维就不是好运维的理念，下面介绍一下ubuntu系统安装

!!! info "准备工作"
    - 步骤一: 下载iso镜像
        - 下载地址: https://mirrors.aliyun.com/ubuntu-releases/
    - 步骤二: 制作系统盘
        - 可以参考使用技巧中的Mac制作系统盘这篇文章
    - 步骤三: 装就完事了

1.1. 选择语言
![第一步](https://pic.imgdb.cn/item/632d192516f2c2beb1185a77.png)

1.2. 选择键盘（本步骤直接默认按回车即可。）
![第二步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a80.png)

1.3. 配置网络（一般情况会直接跳过这一步）
![第三步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a8b.png)

1.4. 选择代理（默认回车跳过）
![第四步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a94.png)

1.5. 配置镜像源（跳过）

1.6. 选择磁盘（这个步骤比较关键）
![第五步](https://pic.imgdb.cn/item/632d192616f2c2beb1185a9e.png)

选择磁盘这一步需要注意，需要所有磁盘空间分给根分区

![第五步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a6c.png)

![第五步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a7d.png)


1.7. 用户信息

![第六步](https://pic.imgdb.cn/item/632d193416f2c2beb1186a90.png)


1.8. openssh server 切记要选择上 (`切记`)
![第七步](https://pic.imgdb.cn/item/632d193416f2c2beb1186aa0.png)



## **系统初始化**

!!! tip "初始化步骤"
    - 优化内核参数；添加hosts信息；
    - 修改国内apt源
    - 修改内核参数
    - 安装基础软件，gpu驱动
    - 安装docker
        - 安装容器运行时
    - 安装kubernetes
        - 安装指定kubeadm版本

以上初始化可以通过跑ansible来实现，下面具体拆分来配置一下



!!! warning "温馨提示"
    - 以下操作系统版本是以最新的ubuntu22.04 为例子来演示

### **更换国内源**

!!! info "ubuntu22.04 清华源"
    - 需要注意一下，如果apt update 报错，就将https改成http
    - 如果需要添加其他的版本的源可以访问: https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/


Ubuntu 软件仓库镜像
```
cat <<EOF>> /etc/apt/sources.list 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

# deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
# # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF
```



## **安全**

### **五: 系统安全**

通常在企业中，服务器会遭受外来的很多的恶意攻击，那么服务器的安全就显得格外的重要。首先肯定想到的是服务器的帐号和密码管理，通常的情况下会禁止root这样的管理员用户登陆，也会禁止密码这样的方式登陆。

**原因:**
  
  - root用户的权限太高，如果一旦帐号密码泄漏，就会造成很严重的后果。
  
  - 禁止密码方式登陆也是为了安全考虑，毕竟密码丢失也是很平常的事情。推荐使用公钥的方式来登陆服务器。


#### **5.1: 禁止root用户:** （centos/ubuntu都适用）
  
  - 可以修改`/etc/ssh/sshd_config`配置文件
  - 添加: `PermitRootLogin yes` 配置（一般情况下，在完成初始化就禁止root登陆了）
    - yes 为允许root登陆
    - no  为禁止root登陆
  - 重新启动sshd服务。`systemctl restart sshd`
  - 当然也可以加入系统初始化步骤中，略～


#### **5.2: 密钥对来登陆服务器**

生成公钥和私钥
```shell
root@user:~# ssh-keygen   //一路回车
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:J0s/ZHIRTj/UCcDQLHtxd5Qa0p3r2CYlcz7lPS7VaXU root@user
The key's randomart image is:
+---[RSA 3072]----+
|        .=+.+o.o+|
|        .o==.o++.|
|         ooo+.o..|
|        . .. = +E|
|        S.=   X.B|
|       . X   o @+|
|        . o   * o|
|           . . . |
|              .  |
+----[SHA256]-----+
```

这个时候在.ssh目录下生成几个文件

```shell
root@user:~# ll .ssh/
total 16
drwx------ 2 root root 4096 Sep 20 09:46 ./
drwx------ 5 root root 4096 Sep 20 09:35 ../
-rw------- 1 root root    0 May 24 15:30 authorized_keys  // 这个是授权文件
-rw------- 1 root root 2590 Sep 20 09:46 id_rsa         // 这个是私钥文件
-rw-r--r-- 1 root root  563 Sep 20 09:46 id_rsa.pub    //这个是公钥文件
```

将公钥加入user用户下: `.ssh/authorized_keys`

```shell
root@user:/home/user# ls -a .ssh/
.  ..  authorized_keys
```
话不多说测试登陆

```shell
$ ssh user@172.30.42.244    //这是我们使用user用户登陆，就不需要密码了
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-113-generic x86_64)
```

当然了，也可以通过一下这样添加自己的公钥
```shell

curl https://openbayes.com/api/users/lixie/keys.txt >> authorized_keys
```

!!! tip "禁止用户密码登陆"
    - 为了安全的考虑，我们需要关闭用户密码登陆的这种方式
    ```shell
    PubkeyAuthentication yes    # 启用公告密钥配对认证方式 
    RSAAuthentication yes       # 允许RSA密钥
    PasswordAuthentication no   # 禁止密码验证登录,如果启用的话,RSA认证登录就没有意义了
    PermitRootLogin no          # 禁用root账户登录，非必要，但为了安全性，请配置
    ```
    - 这样结合上一步骤，关闭用户账号密码验证方式，只采用密钥对会安全很多。







!!! fail "SSH 无法登陆"
    - 可以ping通但无法ssh
    - ssh -v ip 无明显报错
    - 考虑是否是服务端禁止客户端
    - 在/etc/hosts.allow文件中加上  sshd: ALL ，重启sshd

!!! info "修改网卡配置"
    
```
root@ubuntu:/home/ubuntu# cat /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens18:
      addresses:
      - 192.168.1.114/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
        - 192.168.1.1
        search:
        - 202.106.46.151
  version: 2
```

!!! info "清除内核缓存"
    https://www.tecmint.com/clear-ram-memory-cache-buffer-and-swap-space-on-linux/


## **Ubuntu 系统管理 && 安装及管理程序:**

### **dpkg 包安装**

#### **（1）格式**
- dpkg [选项] 包文件

#### **（2）用法**


| 参数      | Description                          |
| ----------- | ------------------------------------ |
| - i      |  安装 deb 软件包  |
| - r       | 删除 deb 软件包 |
| -r --purge     | 连同配置文件一起删除 |
|  -l   | 查看系统中已安装软件包信息  |
|  -p  | 卸载软件包及其配置文件，但无法解决依赖关系 |


#### **（3）辅助选项**
--force-all  强制安装一个包(忽略依赖及其它问题)
--no-install-recommends    参数来避免安装非必须的文件，从而减小镜像的体积


### **apt 包安装 卸载**

#### **（1）格式**
apt [options] [command] [package ...]

#### **（2）用法**

apt install -y  package_name  //安装

apt remove  package_name   //卸载

apt update  //列出所有可更新的软件清单命令


!!! error "apt update 更新报错"
    ```shell
    root@node2:/etc/apt# apt update
    Reading package lists... Done
    E: Could not get lock /var/lib/apt/lists/lock. It is held by process 27056 (apt-get)
    N: Be aware that removing the lock file is not a solution and may break your system.
    E: Unable to lock directory /var/lib/apt/lists/
    ```
    这个主要的原因是有别的进程占用apt这个进程，可以通过一下方法进行排查
    ```shell
    ps aux | grep -i apt  //过滤出来apt进程，如果没有用可以kill掉，或者等待进程结束
    ```


#### **（3）案例**

```shell
// 过滤出来以rc开头和nvidia的包并卸载
dpkg -l |grep nvidia |grep "^rc" |awk '{print $2}' |grep -E 'nvidia' | xargs dpkg  --purge

dpkg -l |grep nvidia |grep "^ii" |awk '{print $2}' |grep -E '^nvidia' | xargs dpkg --force-all  -r

dpkg -l | grep nvidia  | awk '{print $2}' | xargs apt remove -y

dpkg -l | grep nvidia  | awk '{print $2}' | xargs apt purge -y

```






### **ubuntu 关机或者重启**

```shell
echo b > /proc/sysrq-trigger # 强制重启
```
- https://developer.aliyun.com/article/520273

官网: [参考地址链接](https://www.kernel.org/doc/html/v4.10/admin-guide/sysrq.html?from_wecom=1)







## **六: Linux系统管理-磁盘管理**


### **6.1. 磁盘结构**

1. 硬盘的物理结构
  
  - 盘片: 硬盘有多个盘片，每个盘片2面
  - 磁头: 每面一个磁头

2. 硬盘的数据结构
   扇区: 盘片被分为多个扇形区域，每个扇形区存放512字节的数据
   磁道:统一盘片不同半径的同心圆
   柱面:不同盘片相同半径构成的圆柱面


### **6.2. 磁盘接口**


1. IDE（并口）
2. SATA（串口）
   - 速度快
   - 纠错能力强
3. SCSI 

### **6.3. MBR**

1. 定义: MBR 主引导记录
2. 位置: MBR 位于硬盘第一个物理扇区处



### **6.4. 磁盘分区表示**


![20231027170750](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231027170750.png)








### **6.5. parted 命令**
- 作用: 规划格式化超过2T以上的分区，也可以用于小分区的规划


```
parted /dev/sdb 
mklabel gpt     # 设置分区类型为gpt
mkpart primary 0% 100%  # 开始分区
```
如图所示：

![20231017145706](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231017145706.png)



### **6.6. nvme 模块**

```
nvme list | tail -n +3 | awk '{print $1}' | sed 's/\/dev\///' | sort -V | awk '{print "- name: \""$1"\""}'   # 列举出nvme所有磁盘
nvme list | tail -n +3 | awk '{print $1}' | sed 's/\/dev\///' | sort -V | awk '{print "- name: \""$1"\""}' |wc -l # 统计nvme磁盘
```



```
[wlcb] root@stor1:~# lsblk -o NAME,SERIAL
NAME                      SERIAL
loop0
loop1
loop2
loop3
loop4
sda                       2036E4AD4476
├─sda1
├─sda2
└─sda3
  └─ubuntu--vg-ubuntu--lv
sdb                       2036E4AD436F
nvme0n1                   A0601E19
nvme1n1                   A064696F
nvme5n1                   A06042F7
nvme6n1                   A064684B
nvme7n1                   A06040FA
nvme4n1                   A064562C
nvme2n1                   A06470A3
nvme3n1                   A060568E
nvme8n1                   A0604107
nvme9n1                   A06460A4
nvme10n1                  A06057B6
nvme11n1                  A0604B81
nvme12n1                  A0646025
nvme13n1                  A06089E4
nvme14n1                  A06057B4
nvme15n1                  A0604D99
nvme16n1                  A060946F
nvme17n1                  A0646985
nvme18n1                  A060899F
nvme19n1                  A0646DE4
```




### **Linux系统管理07-文件系统与LVM** 



#### **inode 知识点补充**

当我们在Linux系统中，偶然会遇到一些特殊格式的文件或者目录，通过使用rm 是无法直接删除的，这时可以利用inode号删除文件或者目录。

```shell

[cka] root@node1:/# mkdir /share

[cka] root@node1:/# ll -i  //可以通过以下命令查看文件的inode为805024
total 2097232
805024 drwxr-xr-x   2 root root       4096 Nov 11 17:22 share/
655362 drwxr-xr-x   6 root root       4096 Feb 23  2022 snap/ 
find  . -inum inode号 -delete    // 根据inode来删除该目录

```







#### **附件:**
  - 文章地址: [ubuntu安装参考:](https://www.cnblogs.com/mefj/p/14964416.html) 
  - 文章地址: [parted文章](https://hoxis.github.io/linux%E4%B8%8B%E5%A4%A7%E4%BA%8E2TB%E7%A1%AC%E7%9B%98%E6%A0%BC%E5%BC%8F%E5%8C%96%E5%8F%8A%E6%8C%82%E8%BD%BD.html)