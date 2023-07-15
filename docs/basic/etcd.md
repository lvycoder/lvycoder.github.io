# Etcd 备份
> https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/configure-upgrade-etcd/

!!! info 
    以下备份主要是以kubeadm安装的k8s

## 查看证书的路径

```
[cka] root@master0:/home/lixie# cat  /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.159.81:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.159.81:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt    # 指定 crt 文件
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.159.81:2380
    - --initial-cluster=master0=https://192.168.159.81:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key       # 指定 key 文件
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.159.81:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.159.81:2380
    - --name=master0
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt  # 指定证书文件
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```

### 手动备份

#### 安装etcd客户端

```
apt  install etcd-client 
```

#### 指定路径备份

> 这里将备份指定备份到 /srv/data/，指定的三个文件就是以上标注的三个位置

```
export ETCDCTL_API=3     # 声明etcd-api
mkdir /srv/data/
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /srv/data/etcd-snapshot.db
```

校验结果：
```
etcdctl --endpoints=https://127.0.0.1:2379   --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt  --key=/etc/kubernetes/pki/etcd/server.key   snapshot status  /srv/data/etcd-snapshot.db
```


### 自动备份




### 还原（kubeadm 安装的k8s）

#### 模拟故障
> 这里我模拟删除了这个资源，看一会是否可以还原

```
[ucloud] root@master0:~# k get pod
NAME             READY   STATUS    RESTARTS   AGE
nginx-ds-6mnw5   1/1     Running   0          2d
[ucloud] root@master0:~# k delete ds nginx-ds
daemonset.apps "nginx-ds" deleted
```

#### 确认k8s组件的位置

查看kubelet的状态
```
[ucloud] root@master0:~# systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/kubelet.service.d  # 查看这个目录下的文件
             └─10-kubeadm.conf
     Active: active (running) since Mon 2022-07-04 15:09:15 CST; 1 day 23h ago
       Docs: https://kubernetes.io/docs/home/
   Main PID: 39279 (kubelet)
      Tasks: 17 (limit: 4390)
     Memory: 63.3M
     CGroup: /system.slice/kubelet.service
```

查看文件：/etc/systemd/system/kubelet.service.d/10-kubeadm.conf

```
[ucloud] root@master0:~# cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"  # 查看这个配置文件
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS   
```
查看文件：/var/lib/kubelet/config.yaml

```
[ucloud] root@master0:~# cat /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
......
staticPodPath: /etc/kubernetes/manifests  # 看到这行，就说明配置文件这个manifests下
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
```

#### 停止api-server

```
[ucloud] root@master0:~#  mkdir /opt/backup/ -p
[ucloud] root@master0:~# cd /etc/kubernetes/manifests
[ucloud] root@master0:/etc/kubernetes/manifests# ll
total 24
drwxr-xr-x 2 root root 4096 Jul  3 22:01 ./
drwxr-xr-x 5 root root 4096 Jul  3 21:15 ../
-rw------- 1 root root 2294 Jul  3 22:00 etcd.yaml
-rw------- 1 root root 4036 Jul  3 22:00 kube-apiserver.yaml
-rw------- 1 root root 3541 Jul  3 22:00 kube-controller-manager.yaml
-rw------- 1 root root 1464 Jul  3 22:00 kube-scheduler.yaml
[ucloud] root@master0:/etc/kubernetes/manifests# mv kube-* /opt/backup/   # 移走之后我们会发现不能使用kubectl命令

```

#### 进行还原
> 如果恢复失败需要添加--skip-hash-check参数

```
[ucloud] root@master0:~# etcdctl --endpoints=https://127.0.0.1:2379   --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt  --key=/etc/kubernetes/pki/etcd/server.key   snapshot restore /srv/data/etcd-snapshot.db --data-dir=/var/lib/etcd-restore --skip-hash-check
```

修改etcd的配置文件
>将 volume 配置的 path: /var/lib/etcd 改成/var/lib/etcd-restore

```
[ucloud] root@master0:/etc/kubernetes/manifests# pwd
/etc/kubernetes/manifests
[ucloud] root@master0:/etc/kubernetes/manifests# vim etcd.yaml
  - hostPath:
      path: /var/lib/etcd-restore   # 将改目录修改为还原etcd的位置
      type: DirectoryOrCreate
```

还原k8s组件

```
mv /opt/backup/* /etc/kubernetes/manifests
systemctl restart kubelet
```

校验结果：
> 发现误删除的pod还原成功

```
[ucloud] root@master0:/etc/kubernetes/manifests# k get pod
NAME             READY   STATUS    RESTARTS   AGE
nginx-ds-6mnw5   1/1     Running   0          2d
```
