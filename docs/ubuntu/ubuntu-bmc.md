

## **认识BMC **
- 基板管理控制器
- 支持IPMI（智能平台管理接口）

用户可以利用IPMI来监视服务器的物理健康特征，如风扇，电源，内存，磁盘等

好处：
    工程师可以远程在办公室中对服务器开机 关机 重装系统 查看硬件状态
    这样就可以减少去机房的次数，来完成我们的活

## **带外管理口视图:**





## **配置BMC带外管理地址**

```shell
apt-get install ipmitool
ipmitool lan print              # 查看BMC的地址
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr 192.168.2.21
ipmitool lan set 1 netmask 255.255.255.0
ipmitool lan set 1 defgw ipaddr 192.168.2.1
```
这样访问这个地址的443端口，就可以访问到带外管理了。

!!! info "Mac 上ssh转发访问"
    ```
    ssh -L 3443:192.168.2.20:443 router2.c1
    ```

