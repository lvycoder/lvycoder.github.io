
网络通信基础：




CNI 通常有三种实现模式

![](https://pic.imgdb.cn/item/6392a1c4b1fccdcd3625917c.jpg)



官网: https://kubernetes.io/zh-cn/docs/concepts/cluster-administration/networking/


## flannel介绍:

### **网络模式**

github 地址: https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md
flannel 的网络模型（后端）：目前有三种方式实现UDP/VXLAN/host-gw

- UDP : 在最早期flannel使用UDP封装来完成报文的跨主机转发,安全性和性能略有不足(已废弃)

- VXLAN: Linux内核在在2012年底的v3.7.0之后加入了VXLAN协议支持，因此新版本的Flanne1也有UDP转换为VXLAN, VXLAN本质上是一种
tunnel (隧道)协议，用来基于3层网络实现虚拟的2层网络，目前flannel的网络模型已经是基于VXLAN的叠加(覆盖)网络，目前推荐使用
vxlan作为其网络模型。(使用最多)

- Host-gw:也就是Host GateWay, 通过在node节点上创建到达各目标容器地址的路由表而完成报文的转发，因此这种方式要求各node节点本身
必须处于同一个局域网(二层网络)中，因此不适用于网络变动频繁或比较大型的网络环境，但是其性能较好。


### Flannel组件的说明:

Cni0:网桥设备，每创建一个pod都会创建对veth pair, 其中一端是pod中的eth0,另一端是Cni0网桥中的端口(网卡) ，Pod中从网卡
eth0发出的流量都会发送到Cni0网桥设备的端口(网卡)上，Cni0设备获得的ip地址是该节点分配到的网段的第一个地址。

原生模式:
Flannel.1: overlay网络的设备，用来进行vxlan报文的处理(封包和解包)， 不同node之间的pod数据流量都从overlay设备以隧道的形式
发送到对端。


## flannel 的系统文件及目录:


```shell
root@node2:~# find / -name flannel
```

###VXLAN 原生模式:

k3s 默认的 flannel 也默认vxlan,但是从v1.26 开始移除了 wireguard 后端，从而支持 Flannel 原生的 wireguard-native 后端
https://docs.k3s.io/installation/network-options


![](https://pic.imgdb.cn/item/638da221b1fccdcd3640ea59.jpg)


sshd主机上的容器访问别的容器,首先通过网桥判断目的地址是访问当前的地址还是其他主机,如果当前主机的容器不走flannel.1就直接返回了,如果是访问其他
有两种场景;

场景一:
  访问别的 node 上的容器,这时他的主机上就会有对应路由表,例如上图中,可能他要访问的吓一跳就是172.16.78.0/21,那么就会走flannel.1来做报文的封装;这时就走隧道了,不会在物理网卡来做报文的封装.

场景二:
  如果目的地址不是 k8s 的环境,而是外网,那么就会匹配路由的时候就不会走隧道设备,在内核做物理网卡的封装,通过宿主机出去.

不同的主机的容器通信需要通过flannel.1 进行封装和解封

好处: 可以跨子网通信

缺点: 性能差点

### DirectRouting模式:

VXLAN DirectRoutinghost-gw（布尔值）：当主机位于同一子网上时启用直接路由（如）。VXLAN 将仅用于封装数据包到不同子网上的主机。默认为false. Windows 不支持 DirectRouting

开启了这个模式,那网络就会提升,原因就是在同网段不进行封装,只有跨子网才进行封装.

监听端口:

```shell
[openbayes-enflame] root@node1:~# ss -auntp |grep 8472
udp  UNCONN    0      0                     0.0.0.0:8472                0.0.0.0:*
```


## host-gw 模式：

和DirectRouting类似,但是不能跨子网
Use host-gw to create IP routes to subnets via remote machine IPs. Requires direct layer2 connectivity between hosts running flannel.

host-gw provides good performance, with few dependencies, and easy set up.


flannel 总结: 推荐使用VXLAN DirectRouting
相同的 node 子网通信,不需要overlay封装和解封装,而且还可以支持 node 跨子网


## 网络组件caclio

官网地址: https://projectcalico.docs.tigera.io

GitHub 地址: https://github.com/projectcalico/calico

Calico是一个纯三层的网络解决方案，为容器提供多node间的访问通信，calico将每一个node节点都当做为一个路由器(router), 各节点通过BGP(Border Gateway Protocol)边界网关协议学习并在node节点生成路由规则，从而将不同node节点上的pod连接起来进行通信。


Calico 介绍:
网络通过第3层路由技术(如静态路由或BGP路由分配)或第2层地址学习来感知工作负载IP地址。因此它们可以将未封装的流量路由到作为最终目的地的端点的正确主机。但是并非所有网络都能够路由工作负载IP地址。例如公共云环境、跨VPC子网边界的AWS,以及无法通过BGP 、Calico对应到under lay网络或无法轻松配置静态路由的其他场景，这就是为什么Calico支持封装，因此您可以在工作负载之间发送流量，而无需底层网络知道工作负载IP地址。


calico封装类型:
Calico支持两种类型的封装: VXLAN和IP-in-IP, VXLAN在IP中没有 IP的某些环境中受支持(例如Azure)，VXLAN的每 数据包开销稍高，因为报头较大，但除非您运行的是网络密集型工作负载，否则您通常不会注意到这种差异。这两种封装之间的另一个小差异是Cal ico的VXLAN实现不使用BGP, Calico的IP-in-IP是在Calico节点之间使用BGP协议实现跨子网。

Calico两种网络模式

Calico本身支持多种网络模式，从overlay和underlay上区分。Calico overlay 模式，一般也称Calico IPIP或VXLAN模式，不同Node间Pod使用IPIP或VXLAN隧道进行通信。Calico underlay 模式，一般也称calico BGP模式，不同Node Pod使用直接路由进行通信。在overlay和underlay都有nodetonode mesh(全网互联)和Route Reflector(路由反射器)。如果有安全组策略需要开放IPIP协议；要求Node允许BGP协议，如果有安全组策略需要开放TCP 179端口；官方推荐使用在Node小于100的集群，我们在使用的过程中已经通过IPIP模式支撑了100-200规模的集群稳定运行。



BGP是一个去中心化的协议，它通过自动学习和维护路由表实现网络的可用性，但是并不是所有的网络都支持BGP,另外为了跨网络
实现更大规模的网络管理，calico 还支持IP-in-IP的叠加模型，简称IPIP, IPIP可以实现跨不同网段建立 路由通信，但是会存在安全性问题，其在内核内置，可以通过Calico的配置文件设置是否启用IPIP， 在公司内部如果k8s的node节点没有跨越网段建议关闭IPIP。


IPIP是一-种将各Node的路由之间做一个tunnel, 再把两个网络连接起来的模式。启用IPIP模式时，Calico将在各Node上创建一个名为" tun10"的虚拟网络接口。
BGP模式则直接使用物理机作为虚拟路由路(vRouter) ，不再创建额外的tunnel.


Calio 架构:

![](https://pic.imgdb.cn/item/6392c81db1fccdcd365f5388.jpg)

Calio 组件:

- Felix: calico的agent, 运行在每一台node节点上， 其主要是维护路由规则、汇报当前节点状态以确保pod的夸主机通信。

- BGP Client: 每台node都运行，其主要负责监听node节点上由felix生成的路由信息，然后通过BGP协议广播至其他剩余的node节点，从而相互学习路由实现pod通信。

- Route Reflector:集中式的路由反射器，calico v3.3开始支持，当Calico BGP客户端将路由从其FIB(Forward InformationdataBase,转发信息库)通告到Route Reflector时，Route Reflector 会将这些路由通告给部署集群中的其他节点，Route Reflector专门用于管理BGP网络路由规则，不会产生pod数据通信。



注: calico默认工作模式是BGP的node- to-node mesh,如果要使用Route Reflector 需要进行相关配置。
https://docs.projectcalico.org/v3.4/usage/routereflector
https://docs.projectcalico.org/v3.2/usage/routereflector/calico-routereflector

https://blog.kelu.org/category/tech.html
https://blog.kelu.org/tech/2020/01/11/calico-series-3-calico-components-and-arch.html

![](https://pic.imgdb.cn/item/638deb6fb1fccdcd36b39ff8.jpg)








开启 ip-ip 模式,可以看到后面有个隧道tunl0 (兼容性好,可以跨子网)
![](https://pic.imgdb.cn/item/638dbf48b1fccdcd366e5290.jpg)


![](https://pic.imgdb.cn/item/63920dc6b1fccdcd3688ce25.jpg)

![](https://pic.imgdb.cn/item/63921500b1fccdcd36928490.jpg)

总结:

原则使用:

1. 自建机房优先使用 caclio 
  caclio 支持网络策略
  性能高于 flannel

2. 使用启用overlay
  考虑后期的网络扩展,node 节点是否存在跨子网的问题

3. 不启用 overlay
    flannel host-gw
    caclio bgp (直接路由)

4. 启用 overlay
    caclio IPIP
    flannel vxlan
5. CrossSubnet: 表示（ipip-bgp混合模式），指“同子网内路由采用bgp，跨子网路由采用ipip

在使用场景上当主机节点处于不同网络分段，需要跨网段通信时，BGP模式将会失效，此时要使用IPIP模式。 Calico的BGP Mesh模式适合在小规模集群(节点数量小于100个)中直接互联，由于随着集群节点数量的增加，路由规则将成指数级增长会给集群网络带来很大压力。大规模集群需要使用BGP Route Reflector

GitHub 地址: https://github.com/projectcalico/calico/blob/79b442a53adb7d7f1fd62927d9322daf87dce9de/calico/reference/public-cloud/aws.md

## 不同组件压测调研

调研不同网络组件对网络的影响:(同等配置下)

docker-compose 就不需要做 overlay 的封装和解封装,性能是最好的.
![](https://pic.imgdb.cn/item/6391ff44b1fccdcd36702740.jpg)

压测调研:
![](https://pic.imgdb.cn/item/63920012b1fccdcd36714ead.jpg)

flannel 网络组件
![](https://pic.imgdb.cn/item/63920049b1fccdcd3671b07d.jpg)
压测调研:
![](https://pic.imgdb.cn/item/63920120b1fccdcd36732eab.jpg)

DirectRouting模式:
![](https://pic.imgdb.cn/item/6392079eb1fccdcd367dff6f.jpg)

升级系统
![](https://pic.imgdb.cn/item/63920808b1fccdcd367ea518.jpg)

calico 组件:

![](https://pic.imgdb.cn/item/63920844b1fccdcd367ef497.jpg)

![](https://pic.imgdb.cn/item/63920888b1fccdcd367fd2f3.jpg)

![](https://pic.imgdb.cn/item/639208b2b1fccdcd36800790.jpg)

关闭 IPIP
![](https://pic.imgdb.cn/item/6392090fb1fccdcd36807566.jpg)
使用 BGP
![](https://pic.imgdb.cn/item/63920951b1fccdcd3680c7c3.jpg)


但是这个结果还是达不到预期的效果,最后的解决方案是单机多副本

![](https://pic.imgdb.cn/item/639209fcb1fccdcd36819c37.jpg)

![](https://pic.imgdb.cn/item/63920a27b1fccdcd3681f608.jpg)


## 网络性能测试对比

![](https://pic.imgdb.cn/item/638db721b1fccdcd3660cabd.jpg)


自己压测:
caclio 的IPIP模式:
![](https://pic.imgdb.cn/item/63a018f9b1fccdcd36593df3.jpg)




文章参考: 

- https://system51.github.io/2020/05/27/using-calico/

- https://projectcalico.docs.tigera.io/

- https://blog.frognew.com/2021/07/relearning-container-22.html#%E5%8F%82%E8%80%83

- https://kiddie92.github.io/2019/01/23/kubernetes-%E6%80%A7%E8%83%BD%E6%B5%8B%E8%AF%95%E6%96%B9%E6%B3%95%E7%AE%80%E4%BB%8B/

- https://gist.github.com/baymaxium/7797f226fe03d38461f33fdd02145b11