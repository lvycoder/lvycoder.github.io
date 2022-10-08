# **上海交大修复pv步骤**

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