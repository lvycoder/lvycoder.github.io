
## mgr pool 副本调整

![20231018140645](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231018140645.png)

- ceph 集群默认安装好有`.mgr`这样的一个池,而他默认的副本是三个,所以会在有些场景不适用
  
```
ceph osd pool set .mgr size 1 --yes-i-really-mean-it
```

## ceph 存储pool无法创建

!!! error "报错提示:"
    ```
    Warning  ReconcileFailed  28s (x14 over 73s)  rook-ceph-block-pool-controller  
    failed to reconcile CephBlockPool "rook-ceph/replicapool". invalid pool CR "replicapool" spec: 
    error pool size is 1 and requireSafeReplicaSize is true, must be false
    ```
在我们使用ceph集群创建pool时，有时候可能会对副本的数量做一些调整，例如将3调整为1（但是会出现以下的报错）

**解决方法:**

- 这个错误是由于将副本调整为1，需要将 `requireSafeReplicaSize` 改成 `false` 这样才能正确的创建pool

## 修复unknown PG

```
# 列出状态为 unkown 的 PG, 第一列为 pgid
$ ceph pg dump | grep unknown

# 强制重建 PG，注：会丢失数据，慎重使用
$ ceph osd force-create-pg <pgid>
```