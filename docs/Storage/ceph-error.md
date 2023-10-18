

## ceph 存储副本调整

在我们使用ceph集群创建pool时，有时候可能会对副本的数量做一些调整，例如将3调整为1（但是会出现以下的报错）

- 报错提示:
```
Warning  ReconcileFailed  28s (x14 over 73s)  rook-ceph-block-pool-controller  \
failed to reconcile CephBlockPool "rook-ceph/replicapool". invalid pool CR "replicapool" spec: 
error pool size is 1 and requireSafeReplicaSize is true, must be false
```

- 这个错误是由于将副本调整为1，需要将 `requireSafeReplicaSize` 改成 `false` 这样才能正确的创建pool