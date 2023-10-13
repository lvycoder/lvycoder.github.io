
## **程序与用户交互**
用户交互: 就是人往计算机 input 内容,计算机print 结果

1. input 输入
2. print 输出


| 主机名 | ip 地址 | 内存/系统磁盘 | 容器数据盘 | 服务 |
|---|---|---|---|---|
| m1 | 192.168.1.x | 8G 系统盘 | 2T sata  sda | k8s-m1,keepalived,haproxy|
| m2 | 192.168.1.x | 8G 系统盘 | 2T sata  | k8s-m2,keepalived,haproxy|
| m3 | 192.168.1.x | 8G 系统盘 | 2T sata  | k8s-m3,keepalived,haproxy|
| node1 | 192.168.1.x | 2T 系统盘 | 无 | 无 |
