# **天津大学集群问题**




!!! info "问题复现"
从下图可以看出有很多的任务处于数据同步关闭的一个状态
![openbayes状态](https://pic.imgdb.cn/item/632d7e3e16f2c2beb18e3b80.jpg)

!!! note "问题排查"
查看k8s集群的状态，发现一下pod处于异常状态，这些异常的pod只能全部删除重建
![集群中pod状态](https://pic.imgdb.cn/item/632d7e8a16f2c2beb18e878e.png)
需要查看一下异常pod的详细信息
![查看异常pod的详细信息](https://pic.imgdb.cn/item/632d7e3e16f2c2beb18e3b77.png)

!!! error "问题出现"
    - 以上可以看到pod在创建编号为9的gpu出现报错，导致这样的情况可能就是gpu出问题了
    - 接下来可以检查这个pod所在的机器上的gpu，看是否出现问题
    - 可以通过 nvidia-smi -L 命令来查看

!!! error "检查gpu"
    - 出现以下情况，尝试重启看看是否能修复
![查看gpu](https://pic.imgdb.cn/item/632d7e3e16f2c2beb18e3b87.png)



天津大学集群gpu硬件损坏

!!! info "GPU损坏"
    - 可以通过nvidia-smi -L 查看gpu情况

```shell
nvidia-smi
Unable to determine the device handle for GPU 0000:89:00.0: Unknown Error
```

感觉是这块卡 0000:89:00.0 出问题了。然后去执行下 dmesg 看看情况：

```shell
$ dmesg -T
[Mon May  9 20:37:33 2022] xhci_hcd 0000:89:00.2: PCI post-resume error -19!
[Mon May  9 20:37:33 2022] xhci_hcd 0000:89:00.2: HC died; cleaning up
[Mon May  9 20:37:34 2022] nvidia-gpu 0000:89:00.3: i2c timeout error ffffffff
[Mon May  9 20:37:34 2022] ucsi_ccg 6-0008: i2c_transfer failed -110
```

```shell
$ nvidia-smi drain  -p 0000:89:00.0 -m 1
Successfully set GPU 00000000:89:00.0 drain state to: drainin
```
屏蔽完成这台机器，需要进行重新启动