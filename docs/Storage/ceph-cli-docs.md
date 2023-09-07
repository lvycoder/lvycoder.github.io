## 前言

Ceph是一种开源的分布式存储系统，用于存储和管理海量数据。以下是一些常用的ceph命令案例：


### **ceph 相关命令**

- 查看cluster状态

```
ceph -s
```

- 查看所有pool

```
ceph osd lspools
```

- 设置pool副本数量

```
ceph osd pool set .mgr size 1 --yes-i-really-mean-it
```

- 查看 pool 副本数量
  
```
ceph osd pool get <pool-name> size
```

- 查看 ceph 集群中每个 pool 的副本数量
  
```
ceph osd pool ls detail
```

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


### **修复 pg 命令**

```
ceph pg dump | grep unknown

ceph osd force-create-pg <pgid>
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