## **RBD块存储**

- 校验pool安装情况

```
ceph osd lspools # 查看pool

ceph osd pool create rook 16 16 # 创建一个rook池

rbd create -p rook --image rook-rbd.img --size 10G # 在pool上创建RBD块设备
rbd info rook/rook-rbd.img # 查看块的详细信息

ceph osd pool get replicapool size # 查看pool副本
```

- 客户挂载RBD块
  
```
[pre] root@m1:~# rbd showmapped
id  pool         namespace  image                                         snap  device
0   replicapool             csi-vol-a5f69213-4bbd-11ee-bfc4-4e736d2f91be  -     /dev/rbd0
1   replicapool             csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2  -     /dev/rbd1

[pre] root@m1:~# mkfs.xfs /dev/rbd1
[pre] root@m1:~# mount /dev/rbd1 /data
```

- 查看replicapool的块

```
bash-4.4$ rbd ls -l replicapool
NAME                                          SIZE     PARENT  FMT  PROT  LOCK
csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2  110 GiB            2
csi-vol-a5f69213-4bbd-11ee-bfc4-4e736d2f91be   50 GiB            2
csi-vol-d3ab89af-5069-11ee-bfc4-4e736d2f91be   50 GiB            2

bash-4.4$ rbd -p replicapool info csi-vol-36c61ced-39af-11ee-821b-2e922eb2eef2
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