## **网络 思科设备**

### **路由器**

- cisco 路由设备的基本配置

```shell
en
conf t
no ip domain-lo
line con 0 
exec-t 0 0
logg syn
end
```

- 配置IP(实现互通)

```shell
int f 0/1
ip address ip_address subnet_mask
no shutdown
```

!!! warning "温馨提示"
    一般来说，路由器的物理接口默认都是关闭的，需要用“no shutdown” 命令开启；但交换机的物理接口默认都是开启

### **静态路由**

![20231103152941](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231103152941.png)

- 静态路由

- 默认路由

两种配置方式:
```
# 静态路由
ip route 未知网段 子网掩码 下一跳 

# 默认路由
ip route 0.0.0.0 0.0.0.0 下一跳 

```

### **交换机**

给交换机配置IP地址并不像路由器那样配置在物理接口上，而是配置在虚拟接口上，这样，无论任何一个物理接口连接交换机都可以访问虚拟接口的IP地址，从而实现对交换机的管理

```
int vlan 1
ip address ip_address subnet_address
no shutdown
```


## **虚拟局域网**

简介: 随着网络规模的不断扩大，接入的主机越来越多，网络中的广播流量也随之加大。这样就会加重交换机的负担，甚至可能导致交换机死机，那么有没有一种方法来分割交换机上的广播域呢? 本章将要讲解的 VLAN (Virtual Local Area Network，虚拟局域网) 技术，可以从逻辑上将一个大的网络划分成若干小的虚拟局域网。VLAN 技术不仅能够控制广播，还可以增强网络的安全性