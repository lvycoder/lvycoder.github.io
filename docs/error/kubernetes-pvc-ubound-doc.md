# kubernetes 升级导致pvc无法Bound

- k8s v1.19 升级 k8s v1.20
- rook-ceph:v1.0.3

## 报错内容
以下报错来源于ceph-operator

```
controller.go:1213] provision "default/rbd-pvc" class "ceph-ext4": unexpected error getting claim reference: selfLink was empty, can't make reference
E0720 10:01:18.054984 7 controller.go:1213] provision "default/admin-9ktquk6q7gew-scratch" class "ceph-ext4": unexpected error getting claim reference: selfLink was empty, can't make reference
```

## 修复方法

这个错误是由于 Kubernetes 1.20 版本中默认禁用了 `selfLink`。这是一个已知问题，并且已经在 Rook 的更新版本中修复。

`selfLink` 是 Kubernetes 对象的一个字段，用于表示该对象的 RESTful API 路径。但是由于一些原因，Kubernetes 1.20 版本开始默认禁用了这个字段。

解决这个问题的方法有两种：

1. 更新 Rook/Ceph 版本：Rook 的更新版本已经修复了这个问题，不再依赖 `selfLink` 字段。如果可能的话，建议您更新 Rook/Ceph 到最新版本。

2. 临时启用 `selfLink`：如果您不能立即更新 Rook/Ceph，可以临时启用 `selfLink`。在 Kubernetes API 服务器的启动参数中添加 `--feature-gates=RemoveSelfLink=false`。不过请注意，这只是一个临时的解决方案，因为未来的 Kubernetes 版本可能会完全移除 `selfLink`。

在应用上述修改后，您可能需要重启 Kubernetes API 服务器和 Rook/Ceph 服务。

