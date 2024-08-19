## 前言

Ceph是一种开源的分布式存储系统，用于存储和管理海量数据。以下是一些常用的ceph命令案例：


### **ceph 相关命令**

| 操作                             | 命令                                                         |
|----------------------------------|--------------------------------------------------------------|
| 查看 cluster 状态                 | `ceph -s`                                                    |
| 查看所有 pool                     | `ceph osd lspools`                                           |
| 删除 pool              |  `ceph osd pool delete {pool-name} [{pool-name} --yes-i-really-really-mean-it]`   |
| 设置 pool 副本数量               | `ceph osd pool set .mgr size 1 --yes-i-really-mean-it`        |
| 查看 pool 副本数量               | `ceph osd pool get <pool-name> size`                         |
| 查看 ceph 集群中每个 pool 的副本数量 | `ceph osd pool ls detail`                                     |


- 查看pool使用率

```
$ ceph df
--- RAW STORAGE ---
CLASS    SIZE   AVAIL    USED  RAW USED  %RAW USED
nvme   14 TiB  14 TiB  10 GiB    10 GiB       0.07
TOTAL  14 TiB  14 TiB  10 GiB    10 GiB       0.07

--- POOLS ---
POOL             ID  PGS    STORED  OBJECTS     USED  %USED  MAX AVAIL
replicapool       1   32  1006 MiB      377  2.0 GiB   0.01    6.6 TiB
myfs-metadata     2   16   127 KiB       25  320 KiB      0    6.6 TiB
myfs-replicated   3   32     4 GiB    1.02k  8.0 GiB   0.06    6.6 TiB
```

- 查看 ceph 版本

```
$ ceph versions
{
    "mon": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 3
    },
    "mgr": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 2
    },
    "osd": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 1
    },
    "mds": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 1
    },
    "rgw": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 2
    },
    "overall": {
        "ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)": 9
    }
}
```

- 查看集群存储状态详情

```
$ ceph df detail
--- RAW STORAGE ---
CLASS     SIZE    AVAIL    USED  RAW USED  %RAW USED
ssd    954 GiB  931 GiB  23 GiB    23 GiB       2.41
TOTAL  954 GiB  931 GiB  23 GiB    23 GiB       2.41

--- POOLS ---
POOL                         ID  PGS   STORED   (DATA)   (OMAP)  OBJECTS     USED   (DATA)   (OMAP)  %USED  MAX AVAIL  QUOTA OBJECTS  QUOTA BYTES  DIRTY  USED COMPR  UNDER COMPR
replicapool                   1   32  511 MiB  511 MiB      0 B      270  511 MiB  511 MiB      0 B   0.06    883 GiB            N/A          N/A    N/A         0 B          0 B
myfs-metadata                 2   16  446 MiB  446 MiB  209 KiB      181  446 MiB  446 MiB  209 KiB   0.05    883 GiB            N/A          N/A    N/A         0 B          0 B
myfs-replicated               3   32  1.6 GiB  1.6 GiB      0 B    1.24k  1.6 GiB  1.6 GiB      0 B   0.18    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.otp              4    8      0 B      0 B      0 B        0      0 B      0 B      0 B      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.log              5    8  3.0 MiB   24 KiB  2.9 MiB      342  3.6 MiB  660 KiB  2.9 MiB      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.meta             6    8  3.4 KiB  3.4 KiB      0 B       16   48 KiB   48 KiB      0 B      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.control          7    8      0 B      0 B      0 B        8      0 B      0 B      0 B      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.buckets.non-ec   8    8      0 B      0 B      0 B        0      0 B      0 B      0 B      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.buckets.index    9    8  164 MiB      0 B  164 MiB       34  164 MiB      0 B  164 MiB   0.02    883 GiB            N/A          N/A    N/A         0 B          0 B
.rgw.root                    10    8  4.5 KiB  4.5 KiB      0 B       16   60 KiB   60 KiB      0 B      0    883 GiB            N/A          N/A    N/A         0 B          0 B
my-store.rgw.buckets.data    11   32   20 GiB   20 GiB      0 B   93.05k   20 GiB   20 GiB      0 B   2.17    883 GiB            N/A          N/A    N/A         0 B          0 B
```

- 查看osd状态

```
$ ceph osd stat
```


- 查看osd状态

```
$ ceph osd dump
```

- 查看mon节点状态

```
$ ceph mon stat
```

- 查看mon节点的dump信息

```
$ ceph mon dump
epoch 3
fsid 860fd586-3f2e-4bd7-8497-4f900de9cd32
last_changed 2023-08-11T10:46:13.617465+0000
created 2023-08-11T10:45:35.787320+0000
min_mon_release 17 (quincy)
election_strategy: 1
0: [v2:10.97.2.200:3300/0,v1:10.97.2.200:6789/0] mon.a
1: [v2:10.97.15.89:3300/0,v1:10.97.15.89:6789/0] mon.b
2: [v2:10.97.9.169:3300/0,v1:10.97.9.169:6789/0] mon.c
dumped monmap epoch 3
```

- ceph 集群的停止或重启

```
ceph osd set noout # 关闭服务前设置noout

ceph osd unset noout # 启动服务后取消noout
```

- 查看cephfs服务状态

```
$ ceph mds stat
myfs:1 {0=myfs-a=up:active}
```










### **修复 pg 命令**

```
ceph pg dump | grep unknown

ceph osd force-create-pg <pgid>
```


### 查看pg状态

```
ceph pg stat
```











### **osd 相关命令**



```
查看OSD列表：ceph osd tree
查看PG状态：ceph pg stat
查看特定PG状态：ceph pg <pg-id> query
查看数据统计信息：ceph df
查看集群状态摘要：ceph status
查看集群监视器状态：ceph mon stat
查看特定OSD状态：ceph osd status <osd-id>
```