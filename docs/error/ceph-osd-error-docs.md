
## 报错提示: 
```
Startup probe failed: ceph daemon health check failed with the following output: admin_socket: exception getting command descriptions: [Errno 2] No such file or directory
```

这个报错是在 ceph 添加 osd 的时候发现的,osd 正好使用是没有问题的,但是探测是一直失败,在相同`/var/run/ceph`路径下 osd-1 没有以 .asok 为后缀