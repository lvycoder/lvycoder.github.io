
在运维的过程中，经常会遇到要清理对象存储中的数据，在rook中推荐了一个s3的工具，叫s3cmd，那么可以利用这个工具对
对象存储中的数据进行上传，下载，删除等操作.


- s3cmd 命令用法:

!!! warning "温馨提示"
    在使用 s3cmd 命令,需要对桶有权限,具体配置可以参考:  https://github.com/barry-boy/note-k8s/issues/115


- 查看 bucket

```
root@rbd-demo-c5fc7f94-89l5k:/# s3cmd ls
2023-08-12 17:18  s3://ceph-bkt-a0842637-c874-4dc7-b0d5-639d6aa825a2
```


- s3cmd 递归删除

```
s3cmd del --recursive s3://ceph-bkt-a0842637-c874-4dc7-b0d5-639d6aa825a2/juicefs-sc/
s3cmd del --recursive s3://ceph-bkt-a0842637-c874-4dc7-b0d5-639d6aa825a2/openbayes-jfs/
```