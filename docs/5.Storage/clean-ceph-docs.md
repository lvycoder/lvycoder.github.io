有很多的时候，我们需要清理整个ceph集群环境，包括一些crd资源，namespace，以及 `/var/lib/rook` 下的内容，当然在清理完整个rook-ceph之后，还需要对osd 已经清理。

!!! warning "关于清理的方法: (官网有一篇文章来说明)"
    - [官方清理rook-ceph集群](https://rook.io/docs/rook/latest-release/Getting-Started/ceph-teardown/#removing-the-cluster-crd-finalizer)


针对osd，官方也给出了一个shell脚本，但是这个脚本只能清理单个磁盘，对此可以对这个脚本做一些修改;

- 针对所以nvme的磁盘就过滤出来，循环的清理。

```
$ cat clear-nvme-osd.sh
#!/bin/bash

# Get a list of all NVMe devices
devices=$(nvme list | awk '{print $1}' | grep -E '^/dev/nvme')

# Loop over each device
for DISK in $devices
do
    echo "Processing $DISK"

    # Zap the disk to a fresh, usable state (zap-all is important, b/c MBR has to be clean)
    sgdisk --zap-all $DISK

    # Wipe a large portion of the beginning of the disk to remove more LVM metadata that may be present
    dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync

    # SSDs may be better cleaned with blkdiscard instead of dd
    blkdiscard $DISK

    # Inform the OS of partition table changes
    partprobe $DISK
done
```