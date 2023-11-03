
## 问题描述

dev 环境因为磁盘出现问题导致存储不可用,提出不可用磁盘,加入新磁盘无法加入

## 问题原因

磁盘坏掉具体不清楚原因,新加入 osd 无法加入 rook-ceph 主要原因有以下几个:

- 使用 ceph 原生方式手动踢出 osd,有些信息残留.
  
    - 报错显示: stderr: Error EEXIST: entity osd.6 exists but key does not match

- operator 无法加入 osd,但是裸设备已经存在 ceph 相关的信息.
    - 从图可以看到vdd已经存在 ceph 相关的信息,但是 vgs 却没有他的记录,也没有 osd 的 deployment

![](https://pic.imgdb.cn/item/639189c7b1fccdcd36a4638b.jpg)
    
- rook-ceph 报空间不足

- pg 25 unknown

![](https://pic.imgdb.cn/item/63918b37b1fccdcd36a63c65.jpg)

## 解决方法

- 将有问题的 osd-6 踢出去 rook-ceph 集群中.

```shell

方式一 : (利用 rook 提供的脚本来删除,推荐!)
脚本地址: https://github.com/rook/rook/blob/v1.6.11/cluster/examples/kubernetes/ceph/osd-purge.yaml

方式二 : 使用 ceph 原生方式删除
[root@node-1 ceph]# kubectl scale deploy rook-ceph-osd-1 --relicas=0 
[root@node-1 ceph]# ceph osd out osd.6
[root@node-1 ceph]# ceph osd purge 6
[root@node-1 ceph]# ceph osd tree //确认是否已经删除
[root@node-1 ceph]# ceph auth del osd.6  //注意可能就是这步骤没有做从而导致集群加不进去新 osd
```


- 清理磁盘已经被 ceph 标记三个 osd

因为配置 Ceph 存储,需要裸设备或者没有文件系统的设备,已经被 ceph 标记也可能 operator 会加入 osd 失败,所以需要清理

方式一:

```shell
[root@node-1 ceph]# dmsetup ls  //用这条命令查出被 ceph 标记的设备
[root@node-1 ceph]# dmsetup remove vg--test-vg--lv
[root@node-1 ceph]# sgdisk -Z /dev/vdd
```
方式二:

```shell
DISK="/dev/sdX"

# Zap the disk to a fresh, usable state (zap-all is important, b/c MBR has to be clean)
sgdisk --zap-all $DISK

# Wipe a large portion of the beginning of the disk to remove more LVM metadata that may be present
dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync

# SSDs may be better cleaned with blkdiscard instead of dd
blkdiscard $DISK

# Inform the OS of partition table changes
partprobe $DISK
```

删除deploy

```
[root@node-1 ceph]# kubectl delete deployments.apps rook-ceph-osd-6  //删除 osd 的 deploy
```

- roo-ceph 空间不足

将名称为 rook 这个 pool 删除来解决的这个问题(这个 pool 不在使用)
```
ceph osd pool delete rook rook  --yes-i-really-really-mean-it  //删除需谨慎
```

- 如果不清楚是具体那块设备出现了问题,可以通过官方提供的脚本来过滤出来

```shell
# Get OSD Pods
# This uses the example/default cluster name "rook"
OSD_PODS=$(kubectl get pods --all-namespaces -l \
  app=rook-ceph-osd,rook_cluster=rook-ceph -o jsonpath='{.items[*].metadata.name}')

# Find node and drive associations from OSD pods
for pod in $(echo ${OSD_PODS})
do
 echo "Pod:  ${pod}"
 echo "Node: $(kubectl -n rook-ceph get pod ${pod} -o jsonpath='{.spec.nodeName}')"
 kubectl -n rook-ceph exec ${pod} -- sh -c '\
  for i in /var/lib/ceph/osd/ceph-*; do
    [ -f ${i}/ready ] || continue
    echo -ne "-$(basename ${i}) "
    echo $(lsblk -n -o NAME,SIZE ${i}/block 2> /dev/null || \
    findmnt -n -v -o SOURCE,SIZE -T ${i}) $(cat ${i}/type)
  done | sort -V
  echo'
done
```

- 修复pg unknown PG

```shell
# 列出状态为 unkown 的 PG, 第一列为 pgid
$ ceph pg dump | grep unknown

# 强制重建 PG，注：会丢失数据，慎重使用
$ ceph osd force-create-pg <pgid>
```

文章参考: https://www.linuxcool.com/dmsetup