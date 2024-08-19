## **外部环境访问集群**

我们在很多的时候，都会在外部环境来访问我们的ceph集群，例如集群中的其他pod，或者宿主机。

如果想访问分为两个步骤:

- 导入ceph配置(这个ceph的配置toolbox pod中就能找的到)
- 安装ceph-common cli 工具



1.从toolbox中获取ceph配置
   
```
bash-4.4$ cat /etc/ceph/
ceph.conf  keyring
bash-4.4$ cat /etc/ceph/ceph.conf # ceph 配置文件
[global]
mon_host = 10.97.15.89:6789,10.97.9.169:6789,10.97.2.200:6789

[client.admin]
keyring = /etc/ceph/keyring # ceph 认证文件
bash-4.4$ cat /etc/ceph/keyring
[client.admin]
key = AQBGEdZk3xCOGBAAAHw7ddjuvvEZwNeqab7d4Q==
```

2.安装ceph-common

```
[pre] root@m1:~# sudo apt install ceph-common
```
