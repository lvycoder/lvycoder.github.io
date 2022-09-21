# Openbayes 线上环境

!!! info "基础环境"
    - 系统: ubuntu22.04  
    - 机器:
        - a100x2
        - amdx2
        - storx2
        - 3090x3
        - a6000 x 1 
    - 交换机:
        - sn2700 x2

由于操作系统为最新的ubuntu22.04 ，ansible-book需要做一些小的调整。

- 添加 ubuntu22.04 镜像源

```shell
echo <<EOF>> /etc/apt/sources.list

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse

EOF
```

这里在ubuntu22.04 系统中的bird无法使用apt安装，所以ansible-playbook需要注释掉，然后手动安装aptitude

!!! info "手动安装aptitude"
    - sudo apt -y install aptitude
    - sudo aptitude update
    - sudo aptitude -y install bird2

### ubuntu22.04 默认cgroup v2导致的lxcfs不生效

文章参考:[lxcfs](https://aisensiy.me/lxcfs-in-kubernetes)
文章参考:[cgroup 修改](https://www.vvave.net/archives/introduction-to-linux-kernel-control-groups-v2.html)


!!! error "现象"
    lxcfs 无法正常工作，导致openbayes容器内部运行free，top，以及显示内核不准确
    问题的原因就是ubuntu22.04 默认只开启了cgroup v2产生

解决方法：
    修改内核参数，开启v1，并重启启动，这个cgroup的问题就能解决了

具体操作：修改配置文件：/etc/default/grub

```shell
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash systemd.unified_cgroup_hierarchy=no systemd.legacy_systemd_cgroup_controller=no"
```

加载内核配置
```
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### k8s 集群新增机器无法ping通ceph mon
!!! info "rp_filter 内核参数影响"

内网问题，与系统多网卡以及这个 rp_filter 参数配置有关系。
新安装的 node 与之前的 node 的 1.0/24 网段路由的下一条接口设备，有些是 sx6036，有些是 s6720ei，就会导致网络包走不同的网卡。rp_filter 的配置会禁止或者允许这种情况

执行以下操作可以规避这个问题
```shell
update-alternatives --set iptables /usr/sbin/iptables-legacy
```


### Openbayes添加存储节点

!!! info "背景"
    - 为了提高存储的读写性能，公司决定添加两台存储节点，共48块ssd。

!!! info "步骤"
    - 将两台机器加入k8s集群中，并打上存储label
    - rook存储涉及到数据同步的问题，先进行`ceph osd set noin, ceph osd set rebalance`为了就是不要让新加的节点直接进行同步，这样让所有的osd加入进来
    再进行同步
    - 修改`k edit  cephcluster rook-ceph`来添加osd，当所有的osd的pod有running，就可以让他们自动同步数据了
    - 将`ceph osd unset noin, ceph osd unset rebalance`取消，并修改ceph osd reweight 0 1


