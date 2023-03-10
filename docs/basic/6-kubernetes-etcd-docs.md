
官网: https://etcd.io/

Github地址: https://github.com/etcd-io/etcd

![](https://pic.imgdb.cn/item/63a49d2f08b68301634b3f0a.jpg)

## ETCD 特性:

![](https://pic.imgdb.cn/item/63a49e7408b68301634c8022.jpg)

- 完全复制: 集群中的每个节点都可以使用完整的存档
- 高可用性: ETCD可以避免硬件的单点故障和网络问题
- 一致性: 每次写入都会返回跨多主机的最新写入
- 简单: 包括一个定义良好,面向用户的API
- 安全: 实现了带有可选的客户端证书身份验证的自动化TLS
- 快速: 每秒一万次写入的基准速度
- 可靠: 使用Raft算法实现存储的合理分布在etcd的工作原理


## 硬件推荐

ETCD 主要考虑内存，CPU，磁盘

官网硬件(推荐): https://etcd.io/docs/v3.5/op-guide/hardware/

!!! warning "温馨提示"
    官方提供的硬件有些过于保守，正式的生产环境最好高于官方推荐的1.5-2倍比较合理

![](https://pic.imgdb.cn/item/63a51b7308b6830163c7130c.jpg)

![](https://pic.imgdb.cn/item/63a51ba608b6830163c75744.jpg)


## ETCD 客户端使用

```shell
root@m1-pre:~# etcdctl member list
4469cb53324fe68b, started, etcd-192.168.1.102, https://192.168.1.102:2380, https://192.168.1.102:2379, false
9f5e0acc1f346641, started, etcd-192.168.1.101, https://192.168.1.101:2380, https://192.168.1.101:2379, false
e519401c4b995768, started, etcd-192.168.1.103, https://192.168.1.103:2380, https://192.168.1.103:2379, false
```


验证当前所有ETCD成员状态
```shell
root@m1-pre:~# export NODE_IPS="192.168.1.101 192.168.1.102 192.168.1.103"
root@m1-pre:~# for ip in ${NODE_IPS};do ETCDCTL_API=3 /usr/bin/etcdctl --endpoints=https://${ip}:2379 --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem endpoint health;done
https://192.168.1.101:2379 is healthy: successfully committed proposal: took = 17.871745ms
https://192.168.1.102:2379 is healthy: successfully committed proposal: took = 12.499902ms
https://192.168.1.103:2379 is healthy: successfully committed proposal: took = 10.525834ms
```


显示详细信息

```shell
root@m1-pre:~# for ip in ${NODE_IPS};do ETCDCTL_API=3 /usr/bin/etcdctl --write-out=table endpoint status  --endpoints=https://${ip}:2379 --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem;done
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.1.101:2379 | 9f5e0acc1f346641 |  3.4.13 |  2.5 MB |      true |      false |       128 |     259947 |             259947 |        |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.1.102:2379 | 4469cb53324fe68b |  3.4.13 |  2.5 MB |     false |      false |       128 |     259947 |             259947 |        |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.1.103:2379 | e519401c4b995768 |  3.4.13 |  2.5 MB |     false |      false |       128 |     259947 |             259947 |        |
+----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

查看ETCD数据

```shell
$ etcdctl get / --prefix  --keys-only
$ etcdctl get /registry/pods/default/test
$ etcdctl get / --prefix  --keys-only |grep namespace
$ etcdctl get / --prefix  --keys-only |grep calico
$ etcdctl get / --prefix  --keys-only |grep deployment

$ ETCDCTL_API=3 etcdctl put /name "linux60"  //增
$ ETCDCTL_API=3 etcdctl get /name            //查
$ ETCDCTL_API=3 etcdctl del /name            //删

$ ETCDCTL_API=3 etcdctl watch /data //无key也可以进行watch
```

watch 如同所示:

![](https://pic.imgdb.cn/item/63a5244408b6830163d22164.jpg)


## ETCD备份恢复

WAL顾名思义，在真正执行写操作之前先写一个日志，预写日志
WAL 存放了预写日志，最大的作用是记录了整个数据变化的的全部历程。在etcd中，所有数据的修改在提交前都要先写入WAL中

V3 版本备份数据
```shell
ETCDCTL_API=3 etcdctl  snapshot save <filename>

```

自动备份数据

```shell
$ mkdir /data/etcd-backup

$ cat etcd-backup.sh
#!/bin/bash
source /etc/profile
DATE=`date +%Y%m%d-%H%M`
ETCDCTL_API=3 /usr/bin/etcdctl snapshot save /data/etcd-backup/etcd-snapshot-${DATE}.db
ETCDFILE=`find /data/etcd-backup -mtime +30 -name etcd-*|wc -l`
if [ ${ETCDFILE} -gt 30 ];then
	find /data/etcd-backup -mtime +30 -name etcd-* -exec rm -f {} \;
fi
```

V3 版本恢复数据

```shell
ETCDCTL_API=3 etcdctl  snapshot restore /data/etcd/etcd.db --data-dir=/opt/data // 恢复的目录必须不存在，否则会报错
```

























