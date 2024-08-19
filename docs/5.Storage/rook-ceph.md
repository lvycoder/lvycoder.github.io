## **rook-ceph简介**
开源的分布式存储系统，支持对象存储，块设备，文件系统

- 块存储
- CephFs 
- 对象存储


### ceph 的版本历史

- x.0.z - 开发版

- x.1.z - 候选版

- x.2.z - 稳定，修正版

### ceph集群角色定义

!!! info "注意"
    ceph集群的osd节点一般保证>=3个，来保证数据的高可用性。

mon : ceph 监视器,在一个主机上运行的一个守护进程，用于维护集群状态映射关系

mgr : 负责跟踪运行时指标和ceph集群的当前状态

osd : 磁盘（真正存储数据的地方）


!!! note "ceph 面试题"
    ceph


## **rook-ceph部署**

!!! info "环境要求"
    一个k8s集群，node节点最少三个节点

mon: 8C 8G/200G  16C 16g/32-200G

### **普通测试部署：**

#### 部署crds，common，operator

```
[ucloud] root@master0:~# git clone --single-branch --branch v1.5.5 https://github.com/rook/rook.git

cd rook/cluster/examples/kubernetes/ceph
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
kubectl create -f cluster.yaml
```
#### 镜像列表：
```
  # ROOK_CSI_CEPH_IMAGE: "quay.io/cephcsi/cephcsi:v3.4.0"
  # ROOK_CSI_REGISTRAR_IMAGE: "k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0"
  # ROOK_CSI_RESIZER_IMAGE: "k8s.gcr.io/sig-storage/csi-resizer:v1.3.0"
  # ROOK_CSI_PROVISIONER_IMAGE: "k8s.gcr.io/sig-storage/csi-provisioner:v3.0.0"
  # ROOK_CSI_SNAPSHOTTER_IMAGE: "k8s.gcr.io/sig-storage/csi-snapshotter:v4.2.0"
  # ROOK_CSI_ATTACHER_IMAGE: "k8s.gcr.io/sig-storage/csi-attacher:v3.3.0"
```

#### CSI获取镜像脚本：
```shell
[ucloud] root@node0:/home/lixie# cat <<EOF>> image-sci.sh
#!/bin/bash

image_list='
csi-node-driver-registrar:v2.0.1
csi-attacher:v3.0.0
csi-snapshotter:v3.0.0
csi-resizer:v1.0.0
csi-provisioner:v2.0.0
'

aliyuncs="registry.aliyuncs.com/it00021hot"
google_gcr="k8s.gcr.io/sig-storage"
for image in $image_list
do
  echo $image
  docker  pull ${aliyuncs}/${image}
  docker  tag ${aliyuncs}/${image} ${google_gcr}/${image}
  docker  rm ${aliyuncs}/${image}
  #echo "${aliyuncs}/${image} ${google_gcr}/${image} downloaded."
done

EOF
```


### **定制化部署：**

#### **定制mon调度参数**

!!! info "背景"
    ⽣产环境有⼀些专⻔的节点⽤于mon、mgr，存储节点节点使⽤单独的节点承担,利⽤调度机制实
    现

```yaml
  placement:
    mon:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-mon
              operator: In
              values:
              - enabled

#设置磁盘的参数，调整为false，⽅便后⾯定制
214     useAllNodes: false
215     useAllDevices: false
```
分别给节点打上标签
```
[ucloud] root@master0:~# kubectl label node node0 ceph-mon=enabled
node/node0 labeled
[ucloud] root@master0:~# kubectl label node node1 ceph-mon=enabled
node/node1 labeled
[ucloud] root@master0:~# kubectl label node node2 ceph-mon=enabled
node/node2 labeled
```

获取镜像脚本
```
$ cat image-rook-ceph-sci-v1.7.11.sh
#!/bin/bash

image_list='
 csi-node-driver-registrar:v2.0.1
 csi-attacher:v3.0.0
 csi-snapshotter:v3.0.0
 csi-resizer:v1.0.0
 csi-provisioner:v2.0.0
'

aliyuncs="registry.aliyuncs.com/it00021hot"
google_gcr="k8s.gcr.io/sig-storage"
for image in $image_list
do
  echo $image
  docker  pull ${aliyuncs}/${image}
  docker  tag ${aliyuncs}/${image} ${google_gcr}/${image}
  #docker  rm ${aliyuncs}/${image}
  #echo "${aliyuncs}/${image} ${google_gcr}/${image} downloaded."
done

EOF
```

#### **定制mgr调度参数**
!!! info "温馨提示"
    修改mgr的调度参数,修改完之后重新apply cluster.yaml配置使其加载到集群中


```yaml
    mgr:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-mgr
              operator: In
              values:
              - enabled
```

此时调度会失败，给node-1和node-2打上 `ceph-mgr=enabled` 的标签

```
$ kubectl label nodes node0 ceph-mgr=enabled
node/node0 labeled
$ kubectl label nodes node1 ceph-mgr=enabled
node/node1 labeled
```

#### **定制msd调度参数**

设置osd的调度参数
```yaml
    osd:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: ceph-osd
              operator: In
              values:
              - enabled
```
定制osd的磁盘参数
```yaml
    nodes:
    - name: "node0"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdb"
    - name: "node1"
      devices: # specific devices to use for storage can be specified for each node
      - name: "vdc"
```



### **toolbox客户端**

apply以下中两个文件的一个就可以，一般选择toolbox.yaml 
```
$ ll tool*
-rw-r--r--  1 beiyiwangdejiyi  staff   1.7K  7 19 17:26 toolbox-job.yaml     # 一次性任务
-rw-r--r--  1 beiyiwangdejiyi  staff   1.4K  7 19 17:26 toolbox.yaml   

kubectl apply -f toolbox.yaml
```

### **k8s访问ceph**

- centos系统：

#### **1. 配置Ceph yum源**
```
[root@node-1 ~]# cat /etc/yum.repos.d/ceph.repo
[ceph]
name=ceph
baseurl=https://mirrors.aliyun.com/ceph/rpm-octopus/el8/x86_64/
enabled=1
gpgcheck=0
```
#### **2.安装ceph-common**
```
[root@node-1 ~]# yum -y install ceph-common
```

#### **3. 创建ceph配置文件**
```
[root@rook-ceph-tools-65c94d77bb-b9b2h /]# cat /etc/ceph/ceph.conf    # 查看之后宿主机创建
[global]
mon_host = 10.43.248.216:6789,10.43.174.200:6789,10.43.9.21:6789

[client.admin]
keyring = /etc/ceph/keyring
[root@rook-ceph-tools-65c94d77bb-b9b2h /]# cat /etc/ceph/keyring      # 查看之后宿主机创建
[client.admin]
key = AQCRS+NijUeiIxAAhFtv6je2FmMEAVHAJJqPwg==
```


- ubuntu系统：

```
apt install ceph-common
```






### **访问RBD块存储**


#### 1.创建一个pool
```yaml
[root@rook-ceph-tools-65c94d77bb-xg6xs /]# ceph osd pool create rook 16 16
pool 'rook' created

[root@rook-ceph-tools-65c94d77bb-xg6xs /]# ceph osd lspools     # 查看pools
1 device_health_metrics
2 replicapool
3 rook
```

#### 2. 在pool上创建块设备

```yaml
[root@rook-ceph-tools-65c94d77bb-xg6xs /]# rbd create -p rook --image rook-rbd.img --size 10G
[root@rook-ceph-tools-65c94d77bb-xg6xs /]# rbd ls -p rook                   
rook-rbd.img
[root@rook-ceph-tools-65c94d77bb-xg6xs /]# rbd info rook/rook-rbd.img       # 查看详细信息
rbd image 'rook-rbd.img':
	size 10 GiB in 2560 objects
	order 22 (4 MiB objects)
	snapshot_count: 0
	id: 50a7fcf85890
	block_name_prefix: rbd_data.50a7fcf85890
	format: 2
	features: layering
	op_features:
	flags:
	create_timestamp: Fri Jul 29 05:40:05 2022
	access_timestamp: Fri Jul 29 05:40:05 2022
	modify_timestamp: Fri Jul 29 05:40:05 2022
```

#### 3、客户挂载RBD块

```shell
[ucloud] root@master0:/home/lixie# rbd map rook/rook-rbd.img
/dev/rbd0

[ucloud] root@master0:/home/lixie# rbd showmapped
id  pool  namespace  image         snap  device
0   rook             rook-rbd.img  -     /dev/rbd0
[ucloud] root@master0:/home/lixie# mkfs.xfs /dev/rbd0
meta-data=/dev/rbd1              isize=512    agcount=16, agsize=163840 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=16     swidth=16 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=16 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

```

!!! bug "问题一：加载 rbd 内核模块失败"
    ```
    [root@rook-ceph-tools-65c94d77bb-xg6xs /]# rbd map rook/rook-rbd.img
    modinfo: ERROR: Module alias rbd not found.
    modprobe: FATAL: Module rbd not found in directory /lib/modules/5.4.0-48-generic
    rbd: failed to load rbd kernel module (1)
    rbd: failed to set udev buffer size: (1) Operation not permitted
    rbd: sysfs write failed
    In some cases useful info is found in syslog - try "dmesg | tail".
    rbd: map failed: (2) No such file or directory
    ```
解决方法：
```
[ucloud] root@node0:/home/lixie# modprobe rbd
[ucloud] root@node0:/home/lixie# lsmod |grep rbd
rbd                   106496  0
libceph               327680  1 rbd
```

!!! warning "问题二：map rdb "
    ```
    [root@rook-ceph-tools-65c94d77bb-b9b2h /]# rbd map rook/rook-rbd.img
    rbd: failed to set udev buffer size: (1) Operation not permitted
    rbd: sysfs write failed
    In some cases useful info is found in syslog - try "dmesg | tail".
    ```

解决方法：
  在宿主机上执行，该命令。


!!! warning "问题三: 内核模块不支持这么多的特性"
    ```
    [dev] root@master0:/home/lixie# rbd map rook/rook-rbd1.img
    rbd: sysfs write failed
    RBD image feature set mismatch. You can disable features unsupported by the kernel with "rbd feature disable rook/rook-rbd1.img object-map fast-diff deep-flatten".
    In some cases useful info is found in syslog - try "dmesg | tail".
    rbd: map failed: (6) No such device or address
    ```

解决方法：
```shell
rbd feature disable rook/rook-rbd1.img object-map fast-diff deep-flatten    # 按照他的提示，先禁止这些特性再map
```



### **Dashbaard 图形管理**

!!! warning "温馨提示"
    注意需要将主机暴漏端口的安全组打开，安全组打开 31926 端口

启⽤之后，可以看到rook-ceph-mgr-dashboard-external-http的service，其类型是NodePort，
```yaml
/Users/beiyiwangdejiyi/k8s-data/rook-v1.6.11/cluster/examples/kubernetes/ceph
k apply -f dashboard-external-http.yaml

$ k get svc -n rook-ceph
NAME                                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
csi-cephfsplugin-metrics                ClusterIP   10.97.7.142    <none>        8080/TCP,8081/TCP   579d
csi-rbdplugin-metrics                   ClusterIP   10.97.0.194    <none>        8080/TCP,8081/TCP   579d
rook-ceph-mgr                           ClusterIP   10.97.15.77    <none>        9283/TCP            579d
rook-ceph-mgr-dashboard                 ClusterIP   10.97.4.98     <none>        7000/TCP            579d
rook-ceph-mgr-dashboard-external-http   NodePort    10.97.10.172   <none>        7000:31926/TCP      8m18s  
```

默认mgr创建了⼀个admin的⽤户，其密码存放在rook-ceph-dashboard-password的secrets对象中，通过如下⽅式可以获取到

```yaml
kubectl get secrets -n rook-ceph rook-ceph-dashboard-password -oyaml
apiVersion: v1
data:
  password: XTBndS0iREN1bE9UMGpQY2JQSSE=   # 采用base64加密 
kind: Secret
metadata:
  creationTimestamp: "2020-12-16T18:01:16Z"
  name: rook-ceph-dashboard-password
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: ceph.rook.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: CephCluster
    name: rook-ceph
    uid: ee10d125-4428-4e88-983a-53190bc3411c
  resourceVersion: "103972533"
  uid: 7082d4ad-47bb-46e2-b439-624016cc5f81
type: kubernetes.io/rook
```

base64 解密
```
$ echo XTBndS0iREN1bE9UMGpQY2JQSSE=  | base64 -d
]0gu-"DCulOT0jPcbPI!%
```

!!! success "测试登陆"
    - URL: http://106.75.119.241:31926/ 
    - 帐号: admin 
    - 密码: ]0gu-"DCulOT0jPcbPI! 

进入就可以看到一下界面

![ceph](/Users/beiyiwangdejiyi/hugo/docs/src/ceph-dashboard.png)


### **Dashboard 监控ceph**


```
$ k get svc -n rook-ceph
NAME                                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
csi-cephfsplugin-metrics                ClusterIP   10.97.7.142    <none>        8080/TCP,8081/TCP   580d
csi-rbdplugin-metrics                   ClusterIP   10.97.0.194    <none>        8080/TCP,8081/TCP   580d
rook-ceph-mgr                           ClusterIP   10.97.15.77    <none>        9283/TCP            580d # 给prometheus作为客户端使用的
......
```

#### **部署Prometheus Operator**

```
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.40.0/bundle.yaml
```

确认prometheus-operator处于run状态
```
$ k get pod
prometheus-operator-7ccf6dfc8-d9dmm             1/1     Running   0          142
```

#### **部署Prometheus Instances**

```
$ git clone --single-branch --branch v1.6.11 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph/monitoring
```
创建服务监视器以及 Prometheus 服务器 pod 和服务
```
kubectl create -f service-monitor.yaml
kubectl create -f prometheus.yaml
kubectl create -f prometheus-service.yaml
```

本地测试访问：
```
$ k port-forward pod/prometheus-rook-prometheus-0 -n rook-ceph  9090 9090

访问：http://localhost:9090/
```

grafana测试访问：
```
$ k port-forward pod/grafana-cc568dbd8-4nvlq -n infra  3000 80

访问：http://localhost:3000/
帐号：admin
密码：strongpassword
```

!!! info "监控展板"
    - Ceph - Cluster：https://grafana.com/grafana/dashboards/2842
    - Ceph - OSD ： https://grafana.com/grafana/dashboards/5336
    - Ceph - Pools： https://grafana.com/grafana/dashboards/5342


### **对象存储**

#### **部署RGW对象存储** 

```shell
$ k apply -f object.yaml

[ucloud] root@master0:~/.kube# kubectl  get svc -n rook-ceph
NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
csi-rbdplugin-metrics      ClusterIP   10.43.40.164    <none>        8080/TCP,8081/TCP   7d4h
csi-cephfsplugin-metrics   ClusterIP   10.43.170.151   <none>        8080/TCP,8081/TCP   7d4h
rook-ceph-mon-a            ClusterIP   10.43.248.216   <none>        6789/TCP,3300/TCP   7d4h
rook-ceph-mon-b            ClusterIP   10.43.174.200   <none>        6789/TCP,3300/TCP   7d4h
rook-ceph-mon-c            ClusterIP   10.43.9.21      <none>        6789/TCP,3300/TCP   7d4h
rook-ceph-mgr-dashboard    ClusterIP   10.43.193.31    <none>        8443/TCP            7d4h
rook-ceph-mgr              ClusterIP   10.43.114.15    <none>        9283/TCP            7d4h
wordpress-mysql            ClusterIP   None            <none>        3306/TCP            7d3h
rook-prometheus            NodePort    10.43.128.1     <none>        9090:30900/TCP      3d
prometheus-operated        ClusterIP   None            <none>        9090/TCP            3d
rook-ceph-rgw-my-store     ClusterIP   10.43.73.235    <none>        80/TCP              18m
[ucloud] root@master0:~/.kube# curl http://10.43.73.235
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult>[ucloud] root@master0:~/.kube#
```

#### **RGW高可用**
```
$ vim object.yaml
 54     instances: 2
```


#### **创建Bucket**
- 创建storageclass

```shell
$ k apply -f storageclass-bucket-delete.yaml
storageclass.storage.k8s.io/rook-ceph-delete-bucket created

```

- 创建bucket

```
$ k apply -f object-bucket-claim-delete.yaml
objectbucketclaim.objectbucket.io/ceph-delete-bucket created
```


#### **容器访问对象存储**


获取ceph-rgw的访问地址

``` yaml hl_lines="4"
$ k get cm ceph-delete-bucket -o yaml
apiVersion: v1
data:
  BUCKET_HOST: rook-ceph-rgw-my-store.rook-ceph.svc
  BUCKET_NAME: ceph-bkt-148b1fa5-7868-42e5-8135-383d357c41cd
  BUCKET_PORT: "80"
  BUCKET_REGION: us-east-1
  BUCKET_SUBREGION: ""
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-05T08:24:27Z"
  finalizers:
  - objectbucket.io/finalizer
  labels:
    bucket-provisioner: rook-ceph.ceph.rook.io-bucket
  name: ceph-delete-bucket
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: objectbucket.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: ObjectBucketClaim
    name: ceph-delete-bucket
    uid: a8c69ebc-1e4d-477c-97e7-479b532962b3
  resourceVersion: "1282724"
  uid: 26786f4b-9371-46fa-8ca9-f470e5e92cb2
```

拿到secrets

``` yaml hl_lines="4 5"
$ k get secrets  ceph-delete-bucket -o yaml
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: Rk9JSjBJNlg0NDVNUVVMVkpGMzc=
  AWS_SECRET_ACCESS_KEY: SVdjaElaeVdUbTNGNkRyZ29UcUQ0R1gzOVlhczR4S1ZmWExERHNYeA==
kind: Secret
metadata:
  creationTimestamp: "2022-08-05T08:24:27Z"
  finalizers:
  - objectbucket.io/finalizer
  labels:
    bucket-provisioner: rook-ceph.ceph.rook.io-bucket
  name: ceph-delete-bucket
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: objectbucket.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: ObjectBucketClaim
    name: ceph-delete-bucket
    uid: a8c69ebc-1e4d-477c-97e7-479b532962b3
  resourceVersion: "1282723"
  uid: 1b0af759-7c7d-4fe4-9a80-ea2615fa8fef
type: Opaque

```





base64 解密
```shell
$ echo Rk9JSjBJNlg0NDVNUVVMVkpGMzc= |base64 -d
FOIJ0I6X445MQULVJF37%

# beiyiwangdejiyi @ beiyiwangdejiyideMacBook-Pro in ~/note-work/hugo on git:main x [14:28:13]
$ echo SVdjaElaeVdUbTNGNkRyZ29UcUQ0R1gzOVlhczR4S1ZmWExERHNYeA== |base64 -d
IWchIZyWTm3F6DrgoTqD4GX39Yas4xKVfXLDDsXx%
```




fio --name=sequential-read --directory=/config --rw=read --refill_buffers --bs=4K --size=200M


```shell
root@nginx-run-685fdf6467-mdl9v:/# fio --name=sequential-read --directory=/config --rw=read --refill_buffers --bs=4K --size=200M
sequential-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
fio-3.25
Starting 1 process
sequential-read: Laying out IO file (1 file / 200MiB)

sequential-read: (groupid=0, jobs=1): err= 0: pid=723: Wed Aug 10 06:28:37 2022
  read: IOPS=98.8k, BW=386MiB/s (405MB/s)(200MiB/518msec)
    clat (nsec): min=378, max=86956k, avg=9833.73, stdev=534902.03
     lat (nsec): min=411, max=86956k, avg=9868.39, stdev=534902.42
    clat percentiles (nsec):
     |  1.00th=[     398],  5.00th=[     486], 10.00th=[     532],
     | 20.00th=[     556], 30.00th=[     580], 40.00th=[     604],
     | 50.00th=[     628], 60.00th=[     644], 70.00th=[     668],
     | 80.00th=[     708], 90.00th=[     804], 95.00th=[     932],
     | 99.00th=[   70144], 99.50th=[  102912], 99.90th=[  456704],
     | 99.95th=[ 1253376], 99.99th=[26083328]
   bw (  KiB/s): min=401376, max=401376, per=100.00%, avg=401376.00, stdev= 0.00, samples=1
   iops        : min=100344, max=100344, avg=100344.00, stdev= 0.00, samples=1
  lat (nsec)   : 500=5.72%, 750=80.66%, 1000=9.78%
  lat (usec)   : 2=1.74%, 4=0.06%, 10=0.17%, 20=0.06%, 50=0.11%
  lat (usec)   : 100=1.17%, 250=0.37%, 500=0.07%, 750=0.02%, 1000=0.02%
  lat (msec)   : 2=0.02%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%
  cpu          : usr=3.29%, sys=17.02%, ctx=571, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=386MiB/s (405MB/s), 386MiB/s-386MiB/s (405MB/s-405MB/s), io=200MiB (210MB), run=518-518msec

root@nginx-run-685fdf6467-mdl9v:/config# fio --name=sequential-read --directory=/config --rw=read --refill_buffers --bs=4K --size=200M
sequential-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
fio-3.25
Starting 1 process

sequential-read: (groupid=0, jobs=1): err= 0: pid=729: Wed Aug 10 06:30:48 2022
  read: IOPS=344k, BW=1342MiB/s (1407MB/s)(200MiB/149msec)
    clat (nsec): min=375, max=7097.8k, avg=2339.11, stdev=39079.52
     lat (nsec): min=406, max=7097.8k, avg=2372.97, stdev=39080.14
    clat percentiles (nsec):
     |  1.00th=[    406],  5.00th=[    524], 10.00th=[    540],
     | 20.00th=[    564], 30.00th=[    588], 40.00th=[    612],
     | 50.00th=[    628], 60.00th=[    644], 70.00th=[    668],
     | 80.00th=[    700], 90.00th=[    748], 95.00th=[    868],
     | 99.00th=[  67072], 99.50th=[  73216], 99.90th=[ 114176],
     | 99.95th=[ 156672], 99.99th=[1122304]
  lat (nsec)   : 500=2.29%, 750=87.79%, 1000=7.05%
  lat (usec)   : 2=0.96%, 4=0.01%, 10=0.15%, 20=0.04%, 50=0.11%
  lat (usec)   : 100=1.42%, 250=0.15%, 500=0.01%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.02%, 4=0.01%, 10=0.01%
  cpu          : usr=25.68%, sys=49.32%, ctx=335, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=1342MiB/s (1407MB/s), 1342MiB/s-1342MiB/s (1407MB/s-1407MB/s), io=200MiB (210MB), run=149-149msec
```


```shell
root@nginx-run-685fdf6467-mdl9v:/config# fio --name=big-file-multi-read --directory=/config --rw=read --refill_buffers --bs=4K --size=200M --numjobs=6
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 6 processes
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
Jobs: 2 (f=2): [_(4),R(2)][100.0%][r=264MiB/s][r=67.7k IOPS][eta 00m:00s]
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=732: Wed Aug 10 06:32:40 2022
  read: IOPS=11.1k, BW=43.5MiB/s (45.6MB/s)(200MiB/4602msec)
    clat (nsec): min=377, max=522247k, avg=89494.70, stdev=4682750.76
     lat (nsec): min=408, max=522247k, avg=89553.19, stdev=4682751.34
    clat percentiles (nsec):
     |  1.00th=[      414],  5.00th=[      516], 10.00th=[      548],
     | 20.00th=[      580], 30.00th=[      620], 40.00th=[      660],
     | 50.00th=[      692], 60.00th=[      732], 70.00th=[      796],
     | 80.00th=[      884], 90.00th=[     1020], 95.00th=[     1192],
     | 99.00th=[    83456], 99.50th=[   218112], 99.90th=[  5144576],
     | 99.95th=[ 20578304], 99.99th=[240123904]
   bw (  KiB/s): min=14080, max=90112, per=18.59%, avg=45625.50, stdev=27571.34, samples=8
   iops        : min= 3520, max=22528, avg=11406.37, stdev=6892.84, samples=8
  lat (nsec)   : 500=3.47%, 750=60.05%, 1000=25.67%
  lat (usec)   : 2=8.49%, 4=0.21%, 10=0.15%, 20=0.08%, 50=0.07%
  lat (usec)   : 100=1.00%, 250=0.33%, 500=0.14%, 750=0.07%, 1000=0.04%
  lat (msec)   : 2=0.06%, 4=0.04%, 10=0.05%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.02%, 250=0.01%, 500=0.01%, 750=0.01%
  cpu          : usr=0.59%, sys=2.00%, ctx=671, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=733: Wed Aug 10 06:32:40 2022
  read: IOPS=10.7k, BW=41.9MiB/s (43.9MB/s)(200MiB/4776msec)
    clat (nsec): min=376, max=734234k, avg=92901.06, stdev=5934361.60
     lat (nsec): min=411, max=734234k, avg=92951.67, stdev=5934362.28
    clat percentiles (nsec):
     |  1.00th=[      402],  5.00th=[      516], 10.00th=[      548],
     | 20.00th=[      588], 30.00th=[      636], 40.00th=[      684],
     | 50.00th=[      732], 60.00th=[      788], 70.00th=[      860],
     | 80.00th=[      940], 90.00th=[     1080], 95.00th=[     1272],
     | 99.00th=[    91648], 99.50th=[   193536], 99.90th=[  3981312],
     | 99.95th=[ 27131904], 99.99th=[233832448]
   bw (  KiB/s): min= 8192, max=98304, per=19.42%, avg=47655.75, stdev=31431.05, samples=8
   iops        : min= 2048, max=24576, avg=11913.88, stdev=7857.79, samples=8
  lat (nsec)   : 500=3.87%, 750=50.45%, 1000=31.27%
  lat (usec)   : 2=12.03%, 4=0.18%, 10=0.15%, 20=0.07%, 50=0.06%
  lat (usec)   : 100=1.02%, 250=0.48%, 500=0.15%, 750=0.05%, 1000=0.04%
  lat (msec)   : 2=0.05%, 4=0.02%, 10=0.03%, 20=0.02%, 50=0.02%
  lat (msec)   : 100=0.02%, 250=0.01%, 500=0.01%, 750=0.01%
  cpu          : usr=0.44%, sys=2.07%, ctx=845, majf=0, minf=17
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=734: Wed Aug 10 06:32:40 2022
  read: IOPS=10.9k, BW=42.6MiB/s (44.7MB/s)(200MiB/4696msec)
    clat (nsec): min=379, max=607583k, avg=91313.18, stdev=4982310.93
     lat (nsec): min=412, max=607583k, avg=91361.07, stdev=4982311.06
    clat percentiles (nsec):
     |  1.00th=[      410],  5.00th=[      516], 10.00th=[      548],
     | 20.00th=[      580], 30.00th=[      620], 40.00th=[      660],
     | 50.00th=[      700], 60.00th=[      740], 70.00th=[      804],
     | 80.00th=[      900], 90.00th=[     1048], 95.00th=[     1240],
     | 99.00th=[    78336], 99.50th=[   130560], 99.90th=[  4882432],
     | 99.95th=[ 14483456], 99.99th=[254803968]
   bw (  KiB/s): min= 7680, max=90112, per=17.01%, avg=41739.89, stdev=24407.57, samples=9
   iops        : min= 1920, max=22528, avg=10434.89, stdev=6101.90, samples=9
  lat (nsec)   : 500=3.93%, 750=58.07%, 1000=25.64%
  lat (usec)   : 2=10.13%, 4=0.22%, 10=0.13%, 20=0.04%, 50=0.08%
  lat (usec)   : 100=1.10%, 250=0.34%, 500=0.08%, 750=0.04%, 1000=0.02%
  lat (msec)   : 2=0.04%, 4=0.03%, 10=0.04%, 20=0.02%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%
  cpu          : usr=0.72%, sys=1.81%, ctx=502, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=735: Wed Aug 10 06:32:40 2022
  read: IOPS=10.6k, BW=41.5MiB/s (43.5MB/s)(200MiB/4822msec)
    clat (nsec): min=374, max=700599k, avg=93757.53, stdev=5099889.71
     lat (nsec): min=413, max=700599k, avg=93803.83, stdev=5099890.00
    clat percentiles (nsec):
     |  1.00th=[      430],  5.00th=[      516], 10.00th=[      540],
     | 20.00th=[      580], 30.00th=[      620], 40.00th=[      660],
     | 50.00th=[      692], 60.00th=[      732], 70.00th=[      804],
     | 80.00th=[      900], 90.00th=[     1048], 95.00th=[     1256],
     | 99.00th=[    91648], 99.50th=[   226304], 99.90th=[  5931008],
     | 99.95th=[ 24248320], 99.99th=[235929600]
   bw (  KiB/s): min= 6520, max=65536, per=15.07%, avg=36989.89, stdev=18379.13, samples=9
   iops        : min= 1630, max=16384, avg=9247.44, stdev=4594.77, samples=9
  lat (nsec)   : 500=3.74%, 750=59.39%, 1000=24.25%
  lat (usec)   : 2=10.19%, 4=0.22%, 10=0.18%, 20=0.08%, 50=0.08%
  lat (usec)   : 100=0.96%, 250=0.43%, 500=0.14%, 750=0.07%, 1000=0.03%
  lat (msec)   : 2=0.06%, 4=0.04%, 10=0.06%, 20=0.02%, 50=0.02%
  lat (msec)   : 100=0.01%, 250=0.02%, 500=0.01%, 750=0.01%
  cpu          : usr=0.21%, sys=2.24%, ctx=874, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=736: Wed Aug 10 06:32:40 2022
  read: IOPS=10.2k, BW=39.9MiB/s (41.9MB/s)(200MiB/5008msec)
    clat (nsec): min=377, max=806541k, avg=97234.58, stdev=6320832.41
     lat (nsec): min=414, max=806541k, avg=97345.92, stdev=6320844.03
    clat percentiles (nsec):
     |  1.00th=[      402],  5.00th=[      516], 10.00th=[      540],
     | 20.00th=[      572], 30.00th=[      612], 40.00th=[      652],
     | 50.00th=[      684], 60.00th=[      724], 70.00th=[      772],
     | 80.00th=[      868], 90.00th=[     1032], 95.00th=[     1240],
     | 99.00th=[    80384], 99.50th=[   154624], 99.90th=[  5275648],
     | 99.95th=[ 20054016], 99.99th=[200278016]
   bw (  KiB/s): min= 8192, max=49152, per=12.40%, avg=30434.00, stdev=15445.75, samples=9
   iops        : min= 2048, max=12288, avg=7608.44, stdev=3861.51, samples=9
  lat (nsec)   : 500=3.77%, 750=62.98%, 1000=22.07%
  lat (usec)   : 2=8.67%, 4=0.18%, 10=0.26%, 20=0.12%, 50=0.12%
  lat (usec)   : 100=1.05%, 250=0.40%, 500=0.11%, 750=0.04%, 1000=0.02%
  lat (msec)   : 2=0.05%, 4=0.04%, 10=0.03%, 20=0.03%, 50=0.02%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%
  cpu          : usr=0.46%, sys=1.96%, ctx=787, majf=0, minf=17
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=737: Wed Aug 10 06:32:40 2022
  read: IOPS=10.3k, BW=40.2MiB/s (42.1MB/s)(200MiB/4977msec)
    clat (nsec): min=378, max=894860k, avg=96613.11, stdev=5799729.12
     lat (nsec): min=413, max=894860k, avg=96658.78, stdev=5799729.19
    clat percentiles (nsec):
     |  1.00th=[      398],  5.00th=[      506], 10.00th=[      540],
     | 20.00th=[      572], 30.00th=[      612], 40.00th=[      644],
     | 50.00th=[      676], 60.00th=[      716], 70.00th=[      764],
     | 80.00th=[      852], 90.00th=[      988], 95.00th=[     1176],
     | 99.00th=[    87552], 99.50th=[   216064], 99.90th=[  6848512],
     | 99.95th=[ 31064064], 99.99th=[231735296]
   bw (  KiB/s): min=16929, max=69632, per=14.42%, avg=35383.25, stdev=17459.47, samples=8
   iops        : min= 4232, max=17408, avg=8845.75, stdev=4364.90, samples=8
  lat (nsec)   : 500=4.66%, 750=63.16%, 1000=22.55%
  lat (usec)   : 2=7.10%, 4=0.20%, 10=0.27%, 20=0.09%, 50=0.11%
  lat (usec)   : 100=0.99%, 250=0.44%, 500=0.12%, 750=0.07%, 1000=0.04%
  lat (msec)   : 2=0.06%, 4=0.04%, 10=0.03%, 20=0.03%, 50=0.01%
  lat (msec)   : 100=0.02%, 250=0.02%, 500=0.01%, 750=0.01%, 1000=0.01%
  cpu          : usr=0.32%, sys=2.05%, ctx=1006, majf=0, minf=17
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=240MiB/s (251MB/s), 39.9MiB/s-43.5MiB/s (41.9MB/s-45.6MB/s), io=1200MiB (1258MB), run=4602-5008msec


root@nginx-run-685fdf6467-mdl9v:/config# fio --name=big-file-multi-read --directory=/config --rw=read --refill_buffers --bs=4K --size=200M --numjobs=6
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 6 processes
Jobs: 3 (f=3): [_(1),R(1),_(1),R(1),_(1),R(1)][80.0%][r=172MiB/s][r=44.1k IOPS][eta 00m:02s]
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=740: Wed Aug 10 06:34:00 2022
  read: IOPS=8276, BW=32.3MiB/s (33.9MB/s)(200MiB/6186msec)
    clat (nsec): min=378, max=805881k, avg=120250.60, stdev=7449083.91
     lat (nsec): min=410, max=805881k, avg=120301.98, stdev=7449084.14
    clat percentiles (nsec):
     |  1.00th=[      422],  5.00th=[      532], 10.00th=[      548],
     | 20.00th=[      580], 30.00th=[      612], 40.00th=[      636],
     | 50.00th=[      660], 60.00th=[      684], 70.00th=[      716],
     | 80.00th=[      748], 90.00th=[      860], 95.00th=[      996],
     | 99.00th=[    77312], 99.50th=[   132096], 99.90th=[  1318912],
     | 99.95th=[ 10289152], 99.99th=[434110464]
   bw (  KiB/s): min= 8192, max=65536, per=23.93%, avg=35045.82, stdev=25507.11, samples=11
   iops        : min= 2048, max=16384, avg=8761.45, stdev=6376.78, samples=11
  lat (nsec)   : 500=2.40%, 750=77.33%, 1000=15.36%
  lat (usec)   : 2=2.64%, 4=0.06%, 10=0.18%, 20=0.11%, 50=0.13%
  lat (usec)   : 100=1.11%, 250=0.39%, 500=0.09%, 750=0.05%, 1000=0.03%
  lat (msec)   : 2=0.03%, 4=0.02%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%
  cpu          : usr=0.34%, sys=1.62%, ctx=845, majf=0, minf=14
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=741: Wed Aug 10 06:34:00 2022
  read: IOPS=6102, BW=23.8MiB/s (24.0MB/s)(200MiB/8390msec)
    clat (nsec): min=379, max=1190.5M, avg=162758.58, stdev=11051920.43
     lat (nsec): min=413, max=1190.5M, avg=162807.90, stdev=11051920.69
    clat percentiles (nsec):
     |  1.00th=[      410],  5.00th=[      524], 10.00th=[      548],
     | 20.00th=[      572], 30.00th=[      604], 40.00th=[      636],
     | 50.00th=[      668], 60.00th=[      700], 70.00th=[      724],
     | 80.00th=[      764], 90.00th=[      876], 95.00th=[     1004],
     | 99.00th=[    78336], 99.50th=[   156672], 99.90th=[  1073152],
     | 99.95th=[  5275648], 99.99th=[616562688]
   bw (  KiB/s): min=  512, max=73728, per=20.69%, avg=30307.20, stdev=21673.33, samples=10
   iops        : min=  128, max=18432, avg=7576.80, stdev=5418.33, samples=10
  lat (nsec)   : 500=2.76%, 750=73.76%, 1000=18.35%
  lat (usec)   : 2=2.79%, 4=0.04%, 10=0.22%, 20=0.13%, 50=0.14%
  lat (usec)   : 100=1.05%, 250=0.42%, 500=0.14%, 750=0.05%, 1000=0.03%
  lat (msec)   : 2=0.04%, 4=0.02%, 10=0.02%, 20=0.01%, 100=0.01%
  lat (msec)   : 250=0.01%, 500=0.01%, 750=0.01%, 2000=0.01%
  cpu          : usr=0.33%, sys=1.10%, ctx=982, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=742: Wed Aug 10 06:34:00 2022
  read: IOPS=6906, BW=26.0MiB/s (28.3MB/s)(200MiB/7413msec)
    clat (nsec): min=380, max=1034.3M, avg=144218.03, stdev=9148025.05
     lat (nsec): min=414, max=1034.3M, avg=144254.80, stdev=9148025.00
    clat percentiles (nsec):
     |  1.00th=[      406],  5.00th=[      524], 10.00th=[      548],
     | 20.00th=[      564], 30.00th=[      596], 40.00th=[      620],
     | 50.00th=[      652], 60.00th=[      676], 70.00th=[      708],
     | 80.00th=[      748], 90.00th=[      860], 95.00th=[      988],
     | 99.00th=[    78336], 99.50th=[   146432], 99.90th=[  1253376],
     | 99.95th=[  4620288], 99.99th=[522190848]
   bw (  KiB/s): min=16384, max=73728, per=26.85%, avg=39318.40, stdev=23491.33, samples=10
   iops        : min= 4096, max=18432, avg=9829.60, stdev=5872.83, samples=10
  lat (nsec)   : 500=3.29%, 750=76.66%, 1000=15.22%
  lat (usec)   : 2=2.43%, 4=0.10%, 10=0.23%, 20=0.12%, 50=0.12%
  lat (usec)   : 100=1.13%, 250=0.37%, 500=0.13%, 750=0.05%, 1000=0.03%
  lat (msec)   : 2=0.04%, 4=0.02%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2000=0.01%
  cpu          : usr=0.32%, sys=1.32%, ctx=864, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=743: Wed Aug 10 06:34:00 2022
  read: IOPS=6106, BW=23.9MiB/s (25.0MB/s)(200MiB/8385msec)
    clat (nsec): min=380, max=1507.9M, avg=162772.24, stdev=13174473.96
     lat (nsec): min=414, max=1507.9M, avg=162810.08, stdev=13174473.94
    clat percentiles (nsec):
     |  1.00th=[      398],  5.00th=[      510], 10.00th=[      540],
     | 20.00th=[      572], 30.00th=[      604], 40.00th=[      636],
     | 50.00th=[      668], 60.00th=[      692], 70.00th=[      724],
     | 80.00th=[      764], 90.00th=[      876], 95.00th=[     1012],
     | 99.00th=[    79360], 99.50th=[   136192], 99.90th=[   897024],
     | 99.95th=[  2506752], 99.99th=[434110464]
   bw (  KiB/s): min=    8, max=81920, per=20.70%, avg=30310.40, stdev=22461.38, samples=10
   iops        : min=    2, max=20480, avg=7577.60, stdev=5615.35, samples=10
  lat (nsec)   : 500=4.29%, 750=73.14%, 1000=17.30%
  lat (usec)   : 2=2.94%, 4=0.04%, 10=0.22%, 20=0.07%, 50=0.19%
  lat (usec)   : 100=1.10%, 250=0.44%, 500=0.11%, 750=0.05%, 1000=0.02%
  lat (msec)   : 2=0.03%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 2000=0.01%
  cpu          : usr=0.05%, sys=1.40%, ctx=993, majf=0, minf=14
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=744: Wed Aug 10 06:34:00 2022
  read: IOPS=6911, BW=26.0MiB/s (28.3MB/s)(200MiB/7408msec)
    clat (nsec): min=381, max=1179.3M, avg=143994.58, stdev=11079777.48
     lat (nsec): min=413, max=1179.3M, avg=144029.70, stdev=11079777.45
    clat percentiles (nsec):
     |  1.00th=[      406],  5.00th=[      516], 10.00th=[      540],
     | 20.00th=[      564], 30.00th=[      580], 40.00th=[      612],
     | 50.00th=[      636], 60.00th=[      668], 70.00th=[      692],
     | 80.00th=[      732], 90.00th=[      836], 95.00th=[      956],
     | 99.00th=[    76288], 99.50th=[   111104], 99.90th=[   995328],
     | 99.95th=[  3227648], 99.99th=[742391808]
   bw (  KiB/s): min= 5040, max=73728, per=22.93%, avg=33587.20, stdev=27492.28, samples=10
   iops        : min= 1260, max=18432, avg=8396.80, stdev=6873.07, samples=10
  lat (nsec)   : 500=3.81%, 750=78.93%, 1000=13.08%
  lat (usec)   : 2=2.02%, 4=0.02%, 10=0.21%, 20=0.07%, 50=0.12%
  lat (usec)   : 100=1.15%, 250=0.36%, 500=0.07%, 750=0.04%, 1000=0.02%
  lat (msec)   : 2=0.04%, 4=0.02%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%, 2000=0.01%
  cpu          : usr=0.26%, sys=1.35%, ctx=724, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=745: Wed Aug 10 06:34:00 2022
  read: IOPS=6238, BW=24.4MiB/s (25.6MB/s)(200MiB/8207msec)
    clat (nsec): min=379, max=1170.8M, avg=159639.78, stdev=10672683.50
     lat (nsec): min=413, max=1170.8M, avg=159675.27, stdev=10672683.47
    clat percentiles (nsec):
     |  1.00th=[      410],  5.00th=[      516], 10.00th=[      540],
     | 20.00th=[      572], 30.00th=[      596], 40.00th=[      628],
     | 50.00th=[      652], 60.00th=[      684], 70.00th=[      716],
     | 80.00th=[      764], 90.00th=[      876], 95.00th=[     1012],
     | 99.00th=[    77312], 99.50th=[   156672], 99.90th=[  1810432],
     | 99.95th=[  5865472], 99.99th=[616562688]
   bw (  KiB/s): min= 6400, max=74752, per=18.50%, avg=27096.62, stdev=22310.47, samples=13
   iops        : min= 1600, max=18688, avg=6774.15, stdev=5577.62, samples=13
  lat (nsec)   : 500=4.00%, 750=74.22%, 1000=16.52%
  lat (usec)   : 2=3.01%, 4=0.05%, 10=0.19%, 20=0.07%, 50=0.11%
  lat (usec)   : 100=1.06%, 250=0.40%, 500=0.14%, 750=0.05%, 1000=0.05%
  lat (msec)   : 2=0.04%, 4=0.03%, 10=0.03%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2000=0.01%
  cpu          : usr=0.26%, sys=1.22%, ctx=949, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=143MiB/s (150MB/s), 23.8MiB/s-32.3MiB/s (24.0MB/s-33.9MB/s), io=1200MiB (1258MB), run=6186-8390msec
```






fio --name=sequential-write --directory=/config --rw=write --refill_buffers --bs=4K --size=200M --end_fsync=1


fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=6


fio --name=sequential-write --directory=/config --rw=write --refill_buffers --bs=4K --size=200M --end_fsync=1


```shell
root@nginx-run-685fdf6467-mdl9v:/config# fio --name=sequential-write --directory=/config --rw=write --refill_buffers --bs=4K --size=200M --end_fsync=1
sequential-write: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
fio-3.25
Starting 1 process
sequential-write: Laying out IO file (1 file / 200MiB)
Jobs: 1 (f=1)
sequential-write: (groupid=0, jobs=1): err= 0: pid=756: Wed Aug 10 06:39:40 2022
  write: IOPS=33.6k, BW=131MiB/s (138MB/s)(200MiB/1525msec); 0 zone resets
    clat (usec): min=7, max=7420, avg=27.69, stdev=125.85
     lat (usec): min=7, max=7420, avg=27.76, stdev=125.85
    clat percentiles (usec):
     |  1.00th=[    8],  5.00th=[    9], 10.00th=[   11], 20.00th=[   12],
     | 30.00th=[   20], 40.00th=[   21], 50.00th=[   22], 60.00th=[   22],
     | 70.00th=[   23], 80.00th=[   24], 90.00th=[   28], 95.00th=[   37],
     | 99.00th=[  118], 99.50th=[  285], 99.90th=[ 1860], 99.95th=[ 3097],
     | 99.99th=[ 4752]
   bw (  KiB/s): min=132286, max=138088, per=100.00%, avg=135187.00, stdev=4102.63, samples=2
   iops        : min=33071, max=34522, avg=33796.50, stdev=1026.01, samples=2
  lat (usec)   : 10=9.54%, 20=24.43%, 50=63.08%, 100=1.75%, 250=0.66%
  lat (usec)   : 500=0.22%, 750=0.09%, 1000=0.05%
  lat (msec)   : 2=0.10%, 4=0.07%, 10=0.03%
  cpu          : usr=9.84%, sys=31.04%, ctx=51905, majf=0, minf=12
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,51200,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=131MiB/s (138MB/s), 131MiB/s-131MiB/s (138MB/s-138MB/s), io=200MiB (210MB), run=1525-1525msec



root@nginx-run-685fdf6467-mdl9v:/config# fio --name=sequential-write --directory=/config --rw=write --refill_buffers --bs=4K --size=200M --end_fsync=1
sequential-write: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1)
sequential-write: (groupid=0, jobs=1): err= 0: pid=759: Wed Aug 10 06:41:20 2022
  write: IOPS=31.3k, BW=122MiB/s (128MB/s)(200MiB/1637msec); 0 zone resets
    clat (usec): min=7, max=9234, avg=30.16, stdev=137.54
     lat (usec): min=7, max=9234, avg=30.21, stdev=137.54
    clat percentiles (usec):
     |  1.00th=[    8],  5.00th=[    9], 10.00th=[   11], 20.00th=[   18],
     | 30.00th=[   20], 40.00th=[   21], 50.00th=[   22], 60.00th=[   22],
     | 70.00th=[   23], 80.00th=[   24], 90.00th=[   29], 95.00th=[   41],
     | 99.00th=[  147], 99.50th=[  379], 99.90th=[ 2311], 99.95th=[ 3064],
     | 99.99th=[ 4490]
   bw (  KiB/s): min=119544, max=132640, per=100.00%, avg=128018.67, stdev=7349.32, samples=3
   iops        : min=29886, max=33160, avg=32004.67, stdev=1837.33, samples=3
  lat (usec)   : 10=7.32%, 20=25.16%, 50=63.95%, 100=2.08%, 250=0.85%
  lat (usec)   : 500=0.23%, 750=0.09%, 1000=0.08%
  lat (msec)   : 2=0.12%, 4=0.11%, 10=0.02%
  cpu          : usr=7.21%, sys=32.64%, ctx=51971, majf=0, minf=13
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,51200,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=122MiB/s (128MB/s), 122MiB/s-122MiB/s (128MB/s-128MB/s), io=200MiB (210MB), run=1637-1637msec
```


fio --name=big-file-multi-write --directory=/config --rw=write --refill_buffers --bs=4K --size=200M --numjobs=6 --end_fsync=1







fio -filename=/config/fio.img -direct=1 -iodepth 32 -thread -rw=randread -ioengine=libaio -bs=4k -size=200m -numjobs=2 -runtime=60 -group_reporting -name=mytest



固态宿主机：

```shell
[ucloud] root@node1:/var/jfsCache# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=6
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.16
Starting 6 processes
Jobs: 6 (f=6): [R(6)][88.9%][r=130MiB/s][r=33.2k IOPS][eta 00m:01s]
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=225237: Fri Aug 12 14:09:04 2022
  read: IOPS=5925, BW=23.1MiB/s (24.3MB/s)(200MiB/8641msec)
    clat (nsec): min=434, max=21757k, avg=168221.11, stdev=1662876.10
     lat (nsec): min=471, max=21757k, avg=168260.51, stdev=1662876.63
    clat percentiles (nsec):
     |  1.00th=[     524],  5.00th=[     540], 10.00th=[     548],
     | 20.00th=[     564], 30.00th=[     572], 40.00th=[     580],
     | 50.00th=[     596], 60.00th=[     612], 70.00th=[     628],
     | 80.00th=[     660], 90.00th=[     732], 95.00th=[     884],
     | 99.00th=[ 3948544], 99.50th=[19005440], 99.90th=[20054016],
     | 99.95th=[20054016], 99.99th=[20054016]
```

内存宿主机：

```shell
[ucloud] root@node1:/var/jfsCache# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=6
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.16
Starting 6 processes

big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=12095: Fri Aug 12 15:05:27 2022
  read: IOPS=966k, BW=3774MiB/s (3957MB/s)(200MiB/53msec)
    clat (nsec): min=520, max=221610, avg=757.38, stdev=2561.09
     lat (nsec): min=553, max=221646, avg=792.50, stdev=2561.18
    clat percentiles (nsec):
     |  1.00th=[   540],  5.00th=[   556], 10.00th=[   556], 20.00th=[   564],
     | 30.00th=[   572], 40.00th=[   580], 50.00th=[   596], 60.00th=[   612],
     | 70.00th=[   644], 80.00th=[   724], 90.00th=[   908], 95.00th=[   940],
     | 99.00th=[  3344], 99.50th=[  3728], 99.90th=[ 19072], 99.95th=[ 43264],
     | 99.99th=[115200]
```


fio --name=small-file-multi-read \
    --directory=/config \
    --rw=read --file_service_type=sequential \
    --bs=4k --filesize=4k --nrfiles=500 \
    --numjobs=2


