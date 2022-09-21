# **Dev集群问题**

!!! warning "rook-ceph集群崩溃"
    - 现象: rook-ceph集群除了mon，所有pod的状态处于CrashLoopBackOff
    - mgr 无法正常工作
    - operator的log中无明显报错，ceph-cluster-controller: failed to get ceph daemons versions, this typically happens during the first cluster initialization. failed to run 'ceph versions'
    - mon 被operator一共起来4个deploy
    - 错误相似度: https://github.com/rook/rook/issues/6530

初步怀疑是rook-ceph的osd和系统磁盘使用快满而导致的集群崩溃，只有mon正常，mgr和osd都异常
!!! error "无法正常running"

```shell
$ kubectl -n rook-ceph get pod -w
...
rook-ceph-mgr-a-7fd6649d8c-jqvmv                0/1     CrashLoopBackOff  35         20h
rook-ceph-osd-0-58c8d8ccf8-96wtd                0/1     Init:CrashLoopBackOff   1          6s
rook-ceph-osd-0-58c8d8ccf8-96wtd                0/1     Init:2/4                2          18s
rook-ceph-osd-0-58c8d8ccf8-96wtd                0/1     Init:Error              2          19s
rook-ceph-osd-0-58c8d8ccf8-96wtd                0/1     Init:CrashLoopBackOff   2          31s
```

首先需要将集群恢复到正常的一个状态，这里有个问题就是mon一个处于一个4副本的状态,有一个副本状态异常

查看异常状态下mon的configmap,这需要将异常的那个pod的所有配置删除

```yaml
$ kg configmap rook-ceph-mon-endpoints -o yaml
apiVersion: v1
data:
  csi-cluster-config-json: '[{"clusterID":"rook-ceph","monitors":["10.0.0.225:6789","10.0.0.10:6789","10.0.0.79:6789","10.0.0.225:6789"]}]'
  data: c=10.0.0.10:6789,a=10.0.0.79:6789,p=10.0.0.225:6789,q=10.0.0.225:6789
  mapping: '{"node":{"a":{"Name":"node1","Hostname":"node1","Address":"10.0.0.79"},"c":{"Name":"node0","Hostname":"node0","Address":"10.0.0.10"},"p":{"Name":"master0","Hostname":"master0","Address":"10.0.0.225"},"q":{"Name":"master0","Hostname":"master0","Address":"10.0.0.225"}}}'
  maxMonId: "16"
kind: ConfigMap
metadata:
  creationTimestamp: "2020-12-16T18:00:19Z"
  name: rook-ceph-mon-endpoints
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: ceph.rook.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: CephCluster
    name: rook-ceph
    uid: ee10d125-4428-4e88-983a-53190bc3411c
  resourceVersion: "555335505"
  uid: 1ee20194-f90e-4736-8d7f-89ac0314556c
```

留下三个正常的mon

```yaml
$ k get configmap rook-ceph-mon-endpoints -o yaml
apiVersion: v1
data:
  csi-cluster-config-json: '[{"clusterID":"rook-ceph","monitors":["10.0.0.225:6789","10.0.0.10:6789","10.0.0.79:6789"]}]'
  data: q=10.0.0.225:6789,c=10.0.0.10:6789,a=10.0.0.79:6789
  mapping: '{"node":{"a":{"Name":"node1","Hostname":"node1","Address":"10.0.0.79"},"c":{"Name":"node0","Hostname":"node0","Address":"10.0.0.10"},"q":{"Name":"master0","Hostname":"master0","Address":"10.0.0.225"}}}'
  maxMonId: "16"
kind: ConfigMap
metadata:
  creationTimestamp: "2020-12-16T18:00:19Z"
  name: rook-ceph-mon-endpoints
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: ceph.rook.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: CephCluster
    name: rook-ceph
    uid: ee10d125-4428-4e88-983a-53190bc3411c
  resourceVersion: "555840878"
  uid: 1ee20194-f90e-4736-8d7f-89ac0314556c
  
```
修改完成发现mgr正在恢复，集群的状态慢慢恢复正常,一直等到集群恢复正常。这时查看集群的状态
还是有一些异常，大概的意思就是mon-a所在的机器的系统盘快满了


![ceph-cluster status](../src/ceph-01.png)

需要进行下一步，扩容系统盘，机器在ucloud云，所以我们先在ui界面进行扩容，这里可以参考[Ucloud扩容](https://docs.ucloud.cn/uhost/guide/disk)

Ubuntu：
```
sudo apt-get install cloud-initramfs-growroot

LANG=en_US.UTF-8
growpart /dev/vda 1
```
这时，我们再进行查看我们的ceph集群

```shell
[root@rook-ceph-tools-84fc455b76-5dlwr /]# ceph -s
  cluster:
    id:     fc55d844-ed6b-4c0b-9f0f-a6b453ffb9b6
    health: HEALTH_WARN
            1 pool(s) do not have an application enabled
            2 pool(s) have no replicas configured

  services:
    mon: 3 daemons, quorum a,c,q (age 20h)
    mgr: a(active, since 18h)
    mds: myfs:1 {0=myfs-b=up:active} 1 up:standby-replay
    osd: 7 osds: 7 up (since 18h), 7 in (since 18h)

  task status:
    scrub status:
        mds.myfs-a: idle
        mds.myfs-b: idle

  data:
    pools:   6 pools, 241 pgs
    objects: 369.17k objects, 92 GiB
    usage:   181 GiB used, 259 GiB / 440 GiB avail
    pgs:     241 active+clean

  io:
    client:   3.3 KiB/s rd, 9.3 KiB/s wr, 3 op/s rd, 1 op/s wr
```