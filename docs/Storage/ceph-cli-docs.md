## 前言

Ceph是一种开源的分布式存储系统，用于存储和管理海量数据。以下是一些常用的ceph命令案例：


### **ceph 相关命令**

### **Ceph 相关命令**

| 操作                             | 命令                                                         |
|----------------------------------|--------------------------------------------------------------|
| 查看 cluster 状态                 | `ceph -s`                                                    |
| 查看所有 pool                     | `ceph osd lspools`                                           |
| 删除 pool                         | `ceph osd pool delete {pool-name} [{pool-name} --yes-i-really-really-mean-it]`   |
| 设置 pool 副本数量               | `ceph osd pool set .mgr size 1 --yes-i-really-mean-it`        |
| 查看 pool 副本数量               | `ceph osd pool get <pool-name> size`                         |
| 查看 ceph 集群中每个 pool 的副本数量 | `ceph osd pool ls detail`                                     |
| 查看 ceph 组件版本               | `ceph versions`                                               |
| 查看 pool 使用率                 | `ceph df`                                                     |
| 查看集群存储状态详情             | `ceph df detail`                                              |
| 查看 OSD 的状态                  | `ceph osd stat`                                               |
| 查看 OSD 的详细状态              | `ceph osd dump`                                               |
| 查看 mon 节点状态                | `ceph mon stat`                                               |
| 查看 mon 节点的 dump 信息        | `ceph mon dump`                                               |
| 停止或重启 Ceph 集群             | `ceph osd set noout` <br> `ceph osd unset noout`              |
| 查看 cephfs 服务状态              | `ceph mds stat`                                               |
| 修复 PG 命令                      | `ceph pg dump | grep unknown` <br> `ceph osd force-create-pg <pgid>` |
| 查看 PG 状态                      | `ceph pg stat`                                                |

### **OSD 相关命令**

| 操作                                 | 命令                                                         |
|--------------------------------------|--------------------------------------------------------------|
| 查看 OSD 列表                        | `ceph osd tree`                                               |
| 查看 PG 状态                         | `ceph pg stat`                                                |
| 查看特定 PG 状态                     | `ceph pg <pg-id> query`                                       |
| 查看数据统计信息                     | `ceph df`                                                     |
| 查看集群状态摘要                     | `ceph status`                                                 |
| 查看集群监视器状态                   | `ceph mon stat`                                               |
| 查看特定 OSD 状态                    | `ceph osd status <osd-id>`                                    |