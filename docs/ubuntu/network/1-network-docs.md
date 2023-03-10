
## **1.1 查看及测试网络**

查看及测试网络配置是管理 Linux 网络服务的第一步，本节将学习 Linux 操作系统中的 网络查看及测试命令。其中讲解的大多数命令以普通用户权限就可以完成操作，但普通用户 在执行/sbin/目录中的命令时需要指定命令文件的绝对路径。

### **1.1.1 查看网络配置**

#### **1. 查看网络接口地址**

（1）查看活动的网络接口设备
若采用 mini 版 CentOS 7 安装的系统，默认是没有 ifconfig 命令的，需要先通过 yum 方式安装 net-tools 软件包，才有 ifconfig 命令。在不带任何选项和参数执行 ifconfig 命令时， 将显示当前主机中已启用（活动）的网络接口信息。例如，直接执行 ifconfig 命令后可以看 到 ens33、lo 这两个网络接口的信息，具体操作如下：


```shell
[root@VM-16-9-centos ]# ifconfig
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:42:7c:2d:55:50  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.16.9  netmask 255.255.252.0  broadcast 10.0.19.255
        inet6 fe80::5054:ff:fe16:3a9  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:16:03:a9  txqueuelen 1000  (Ethernet)
        RX packets 51791902  bytes 9684145526 (9.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 49095710  bytes 7697835155 (7.1 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 14076  bytes 1715488 (1.6 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 14076  bytes 1715488 (1.6 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

（2）查看指定的网络接口信息

当只需要查看其中某一个网络接口的信息时，可以使用网络接口的名称作为 ifconfig 命 令的参数（不论该网络接口是否处于激活状态）。例如，执行“ifconfig ens33”命令后可以 只查看网卡 ens33 的配置信息，具体操作如下：
```shell
[root@VM-16-9-centos ~]# ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.16.9  netmask 255.255.252.0  broadcast 10.0.19.255
        inet6 fe80::5054:ff:fe16:3a9  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:16:03:a9  txqueuelen 1000  (Ethernet)
        RX packets 51792964  bytes 9684253645 (9.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 49096762  bytes 7698009938 (7.1 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```


---

从上述命令显示的结果中，可以获知 ens33 网卡的一些基本信息，如下所述。 

- inet：表示网络接口的 IP 地址，如“192.168.4.11”。 

- netmask：表示网络接口的子网掩码，如“255.255.255.0”。

- broadcast：表示网络接口所在网络的广播地址，如“192.168.4.255”。 

- ether：表示网络接口的物理地址（MAC 地址），如“00:0c:29:3a:81:cc”。网络接 口的物理地址通常不能更改，是网卡在生产时确定的全球唯一的硬件地址。 除此以外，还能够通过“TX”和“RX”等信息了解通过该网络接口发送和接收的数据包个 数、流量等更多属性。


#### **2. 查看主机名称**


在 Linux 操作系统中，相当一部分网络服务都会通过主机名来识别主机，如果主机名配 置不当，可能会导致程序功能出现故障。使用 hostname 命令可以查看当前主机的主机名， 不用添加任何选项或参数，具体操作如下：(另外除了查看主机名还可以使用-i/-I参数来查看ip)

```shell
[root@VM-16-9-centos ~]# hostname
VM-16-9-centos
[root@VM-16-9-centos ~]#
[root@VM-16-9-centos ~]# hostname -i
::1 127.0.0.1
[root@VM-16-9-centos ~]# hostname -I
10.0.16.9 172.17.0.1
```


#### **3. 查看路由表条目**

Linux 操作系统中的路由表决定着从本机向其他主机、其他网络发送数据的去向，是排 除网络故障的关键信息。直接执行“route”命令可以查看当前主机中的路由表信息，在输出结 果中，Destination 列对应目标网段的地址，Gateway 列对应下一跳路由器的地址，Iface 列 对应发送数据的网络接口。若结合“-n”选项使用，可以将路由记录中的地址显示为数字形式，这可以跳过解析主机 名的过程，在路由表条目较多的情况下能够加快执行速度。



```shell
[root@VM-16-9-centos ~]# route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         gateway         0.0.0.0         UG    0      0        0 eth0
10.0.16.0       0.0.0.0         255.255.252.0   U     0      0        0 eth0
link-local      0.0.0.0         255.255.0.0     U     1002   0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
[root@VM-16-9-centos ~]#
[root@VM-16-9-centos ~]#
[root@VM-16-9-centos ~]#
[root@VM-16-9-centos ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.16.1       0.0.0.0         UG    0      0        0 eth0
10.0.16.0       0.0.0.0         255.255.252.0   U     0      0        0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
```



#### **4. 查看网络连接情况**

通过 netstat 命令可以查看当前操作系统的网络连接状态、路由表、接口统计等信息， 它是了解网络状态及排除网络服务故障的有效工具。以下是 netstat 命令常用的几个选项

- -a：显示主机中所有活动的网络连接信息（包括监听、非监听状态的服务端口）

- -n：以数字的形式显示相关的主机地址、端口等信息。

- -r：显示路由表信息。

- -l：显示处于监听（Listening）状态的网络连接及端口信息。

- -t：查看 TCP（Transmission Control Protocol，传输控制协议）相关的信息

- -u：显示 UDP（User Datagram Protocol，用户数据报协议）协议相关的信息。

- -p：显示与网络连接相关联的进程号、进程名称信息（该选项需要 root 权限）。

通常使用“-anpt”组合选项，以数字形式显示当前系统中所有的 TCP 连接信息，同时显 示对应的进程信息。结合管道命令使用“grep”命令，还可以在结果中过滤出所需要的特定记 录。例如，执行以下操作可以查看本机中是否有监听“TCP 22”端口（即标准 Web 服务）的 服务程序，输出信息中包括 PID 号和进程名称。


```shell
[root@VM-16-9-centos ~]# netstat -antp |grep 22
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      4344/sshd
```



除了 netstat，ss 命令也可以查看网络连接情况，它是 Socket Statistics 的缩写，主要 用于获取 socket 统计信息，它可以显示和 netstat 命令类似的输出内容。但 ss 的优势在于 它能够显示更多更详细的有关 TCP 和连接状态的信息，而且比 netstat 更快速更高效。要想 使用 ss 命令，首先确保 iproute 程序包已被安装，可以通过 yum 方式进行安装。(用法类似)

```shell
[root@VM-16-9-centos ~]# ss -antp
State       Recv-Q Send-Q             Local Address:Port                            Peer Address:Port
LISTEN      0      128                            *:22                                         *:*                   users:(("sshd",pid=4344,fd=3))
LISTEN      0      100                    127.0.0.1:25                                         *:*
```


### **1.1.2 测试网络连接**

用户访问网络服务的前提是网络连接处于正常状态。若网络连接不稳定，甚至无法连接， 用户则无法正常访问网络服务。因此，当网络连接出现问题时，需要通过测试网络连接的命 令来确定故障点。下面介绍几个常用的测试网络连接的命令。


#### **1. 测试网络连通性**

```shell
[root@VM-16-9-centos ~]# ping baidu.com
```


#### **2. 测试DNS解析**

```shell
[root@VM-16-9-centos ~]# nslookup www.google.com
Server:		183.60.83.19
Address:	183.60.83.19#53

Non-authoritative answer:
Name:	www.google.com
Address: 174.37.54.20
Name:	www.google.com
Address: 2001::68f4:2e15

[root@VM-16-9-centos ~]# dig www.google.com

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.7 <<>> www.google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 44445
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;www.google.com.			IN	A

;; ANSWER SECTION:
www.google.com.		133	IN	A	199.59.149.206

;; Query time: 1 msec
;; SERVER: 183.60.83.19#53(183.60.83.19)
;; WHEN: 五 11月 18 15:51:47 CST 2022
;; MSG SIZE  rcvd: 48
```


#### **3. iperf 网络测试 **


```shell
server:
iperf -s -p 1234 -i 1

clent:
iperf -c 172.16.240.204 -p 1234 -i 1 -t 20 -w 20w
```

