
# k8s pv 和 pvc


目前PV的提供方式有两种：静态或动态。(pv 没有命名空间限制)
静态PV由管理员提前创建，动态PV无需提前创建，只需指定PVC的StorageClasse即可



### **回收策略**

- Retain：保留，该策略允许手动回收资源，当删除PVC时，PV仍然存在，PV被视为已释放，管理员可以手动回收卷。

- Recycle：回收，如果Volume插件支持，Recycle策略会对卷执行rm -rf清理该PV，并使其可用于下一个新的PVC，但是本策略将来会被弃用，目前只有NFS和HostPath支持该策略。（不推荐使用）

- Delete：删除，如果Volume插件支持，删除PVC时会同时删除PV，动态卷默认为Delete，目前支持Delete的存储后端包括AWS EBS, GCE PD, Azure Disk, or OpenStack Cinder等。

- 可以通过persistentVolumeReclaimPolicy: Recycle字段配置

- [官网文献: pv 回收策略](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/#reclaim-policy)


### **pv 的状态**

- Available：可用，没有被PVC绑定的空闲资源。

- Bound：已绑定，已经被PVC绑定。

- Released：已释放，PVC被删除，但是资源还未被重新使用。

- Failed：失败，自动回收失败。


### **pv/pvc 的创建**

创建PV

```yaml
apiVersion: v1
kind: PersistentVolume     # 资源对象的名称为 pv
metadata:
  name: pv-nfs             # pv 的名称为设置为 pv-nfs
spec:
  capacity:				   # capacity：容量配置
    storage: 5Gi           
  volumeMode: Filesystem   # 卷的模式，目前支持Filesystem（文件系统） 和 Block（块），其中Block类型需要后端存储支持，默认为文件系统

  accessModes:             # 该PV的访问模式(这里可以写多个模式)
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle   # 回收策略
  storageClassName: nfs-slow               # pvc 想绑定 pv,需要指定storageClassName这个名称
  nfs:
    path: /nfs/share 
    server: 192.168.159.201 

```


创建PVC

```yaml

root@ubuntu:/opt/k8s-data/pv-pvc# cat 3-pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs           # pvc的名称
spec:
  storageClassName: nfs-slow    # pv 的storageClassName ,必须一致
  accessModes:
    - ReadWriteMany       			# 必须一致
  resources:
    requests:
      storage: 100Gi
```


**访问模式:**


- ReadWriteOnce:可读可写，但只支持被单个node挂载。该访问模式约束仅有一个node节点可以访问pvc。换句话来说，同一node节点的不同pod是可以对同一pvc进行读写的

- ReadOnlyMany:可以以只读的方式被多个node挂载

- ReadWriteMany:可以以读写的方式被多个node挂载

- ReadWriteOncePod：仅有一个Pod可以访问使用该pvc（Kubernetes >= v1.22）当你创建一个带有pvc访问模式为ReadWriteOncePod的Pod A时，Kubernetes确保整个集群内只有一个Pod可以读写该PVC。此时如果你创建Pod B并引用了与Pod A相同的PVC(ReadWriteOncePod)时，那么Pod B会由于该pvc被Pod A引用而启动失败。




## **上海交大修复pv步骤**

!!! info "这里主要是kubeadm部署的k8s"

##  **现象**
!!! error "PV不知道因为什么原因处于Terminating."

## **修复PV**
文章参考：https://github.com/jianz/k8s-reset-terminating-pv

### 端口转发到本地

```shell
kubectl port-forward pods/etcd-master 2379:2379 -n kube-system
```

### 修复pv
```shell
./resetpv-linux-x86-64 --k8s-key-prefix registry pvc-bd426570-7fc2-4270-bd41-9512262b0790 --etcd-ca=/etc/kubernetes/pki/etcd/ca.crt --etcd-cert=/etc/kubernetes/pki/etcd/server.crt --etcd-key=/etc/kubernetes/pki/etcd/server.key
```
!!! warning
    pvc-bd426570-7fc2-4270-bd41-9512262b0790 是处于Terminating的pv，修复完成pv处于Bound状态


## **k8s升级导致sc无法正常work**

参考地址: [sc无法正常work]( https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/issues/25)


!!! bug
    Using Kubernetes v1.20.0, getting "unexpected error getting claim reference: selfLink was empty, can't make reference

当前的解决方法是编辑 /etc/kubernetes/manifests/kube-apiserver.yaml
```shell
添加这一行：
---feature-gates=RemoveSelfLink=false
```

## **亲和性导致rook-ceph无法正常使用**

!!! bug 
    unable to get monitor info from DNS SRV with service name: ceph-mon
取消亲和性的配置