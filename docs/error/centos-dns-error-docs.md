
在使用Centos 部署k8s集群的时候，发现了以下这个报错，无法修改/etc/resolv.conf 文件

![](https://pic.imgdb.cn/item/65080363204c2e34d39484e7.jpg)

即使我们使用的是root权限也是无法删除很修改这个文件，这就让人摸不着头脑。那么下面介绍一种方式来调整

## **操作步骤**

- 1.检查文件属性

```
sudo lsattr /etc/resolv.conf
```

- 2.利用`chattr`删除文件属性

```
sudo chattr -a /etc/resolv.conf
sudo chattr -i /etc/resolv.conf
```

- 3.这样就可以正常编辑文件了