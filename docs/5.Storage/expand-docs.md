容器的容量的不⾜的时候需要对容器的存储空间进⾏扩容，Rook默认提供了两种驱动：

- RBD
- Cephfs

## **方法一：**

这两种驱动通过StorageClass存储供给者为容器提供存储空间，同时已经⾃动扩容的能⼒，
其流程为：

- 客户端通过PVC声明的⽅式向—>StorageClass申请扩容容量空间—>通过驱动调整PV的容量—>调整底层的RBD镜像块容量，最终达到容量的扩展，如下是操作过程：

```yaml
$ k edit pvc rbd-pvc -o yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"name":"rbd-pvc","namespace":"default"},"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"50Gi"}},"storageClassName":"rook-ceph-block"}}
    pv.kubernetes.io/bind-completed: "yes"
    pv.kubernetes.io/bound-by-controller: "yes"
    volume.beta.kubernetes.io/storage-provisioner: rook-ceph.rbd.csi.ceph.com
    volume.kubernetes.io/storage-provisioner: rook-ceph.rbd.csi.ceph.com
  creationTimestamp: "2023-08-13T07:58:39Z"
  finalizers:
  - kubernetes.io/pvc-protection
  name: rbd-pvc
  namespace: default
  resourceVersion: "48095065"
  uid: f34132d1-5a98-489d-9707-0d3f9ae9962a
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi # 扩容后的大小
  storageClassName: rook-ceph-block
  volumeMode: Filesystem
  volumeName: pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  phase: Bound


$ k get pv pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a # 我们查看 pv发现以后扩容成功
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a   100Gi      RWO            Delete           Bound    default/rbd-pvc   rook-ceph-block            78d
```

查看replicapool中所有的块
```
bash-4.4$ rbd ls -p replicapool
csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2
csi-vol-a5f69213-4bbd-11ee-bfc4-4e736d2f91be
csi-vol-d3ab89af-5069-11ee-bfc4-4e736d2f91be
```


查看pv的详细信息

```yaml
$ k get pv pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a -o yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: rook-ceph.rbd.csi.ceph.com
    volume.kubernetes.io/provisioner-deletion-secret-name: rook-csi-rbd-provisioner
    volume.kubernetes.io/provisioner-deletion-secret-namespace: rook-ceph
  creationTimestamp: "2023-08-13T07:58:39Z"
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a
  resourceVersion: "48095069"
  uid: 44395629-b052-4790-8519-05c2a4a0a59d
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 100Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: rbd-pvc
    namespace: default
    resourceVersion: "7723736"
    uid: f34132d1-5a98-489d-9707-0d3f9ae9962a
  csi:
    controllerExpandSecretRef:
      name: rook-csi-rbd-provisioner
      namespace: rook-ceph
    driver: rook-ceph.rbd.csi.ceph.com
    fsType: ext4
    nodeStageSecretRef:
      name: rook-csi-rbd-node
      namespace: rook-ceph
    volumeAttributes:
      clusterID: rook-ceph
      imageFeatures: layering
      imageFormat: "2"
      imageName: csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2 # pv 对应的RBD块
      journalPool: replicapool # RBD 所在的pool
      pool: replicapool
      storage.kubernetes.io/csiProvisionerIdentity: 1691750730674-8081-rook-ceph.rbd.csi.ceph.com
    volumeHandle: 0001-0009-rook-ceph-0000000000000001-36c61ced-39af-11ee-821b-2e922eb2eef2
  persistentVolumeReclaimPolicy: Delete
  storageClassName: rook-ceph-block
  volumeMode: Filesystem
status:
  phase: Bound
```

查看块所在pool的详细信息

```
bash-4.4$ rbd -p replicapool info  csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2 
rbd image 'csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2':
	size 100 GiB in 25600 objects
	order 22 (4 MiB objects)
	snapshot_count: 0
	id: 1b8e31cc42074
	block_name_prefix: rbd_data.1b8e31cc42074
	format: 2
	features: layering
	op_features:
	flags:
	create_timestamp: Sun Aug 13 07:58:39 2023
	access_timestamp: Sun Aug 13 07:58:39 2023
	modify_timestamp: Sun Aug 13 07:58:39 2023

```

## **方法二：**

RBD块扩容原理

PVC—>PV—>RBD块—>⽂件系统扩容

 - 1、扩容RBD镜像块容量⼤⼩

```
bash-4.4$ rbd -p replicapool resize csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2 --size 110G # 调整大小
Resizing image: 100% complete...done.

bash-4.4$ rbd -p replicapool info  csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2 # 查看发现一扩容成功
rbd image 'csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2':
	size 110 GiB in 28160 objects
	order 22 (4 MiB objects)
	snapshot_count: 0
	id: 1b8e31cc42074
	block_name_prefix: rbd_data.1b8e31cc42074
	format: 2
	features: layering
	op_features:
	flags:
	create_timestamp: Sun Aug 13 07:58:39 2023
	access_timestamp: Sun Aug 13 07:58:39 2023
	modify_timestamp: Sun Aug 13 07:58:39 2023
```

2、登陆容器所在宿主机，扩容⽂件系统的容量

```shell
[pre] root@m1:~# rbd device list
id  pool         namespace  image                                         snap  device
0   replicapool             csi-vol-a5f69213-4bbd-11ee-bfc4-4e736d2f91be  -     /dev/rbd0
1   replicapool             csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2  -     /dev/rbd1
[pre] root@m1:~#
[pre] root@m1:~#
[pre] root@m1:~# rbd device list |grep csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2
1   replicapool             csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2  -     /dev/rbd1

[pre] root@m1:~# resize2fs /dev/rbd1
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/rbd1 is mounted on /var/lib/kubelet/plugins/kubernetes.io/csi/pv/pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a/globalmount/0001-0009-rook-ceph-0000000000000001-36c61ced-39af-11ee-821b-2e922eb2eef2; on-line resizing required
old_desc_blocks = 13, new_desc_blocks = 14
The filesystem on /dev/rbd1 is now 28835840 (4k) blocks long.

[pre] root@m1:~# df -h |grep rbd1 # 这时我们发现已经扩容成功
/dev/rbd1   108G  3.1G  105G   3% /var/lib/kubelet/pods/6e0c06a7-4a42-492e-b3c5-9d9756d530f9/volumes/kubernetes.io~csi/pvc-f34132d1-5a98-489d-9707-0d3f9ae9962a/mount
```

- 最后我们确认一下发现成功扩容
 
![20231030173651](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231030173651.png)