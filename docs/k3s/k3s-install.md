# **私有部署:高可用k3s**

## **前言**

在工作中,经常遇到很多小环境(小于等于 5 台机器),对于这种环境,就可以尝试使用k3s,原因就是因为 k3s 设计很小巧.它相对于标准的 k8s 所用的内存资源要减半，非常适合比较小型的设备.对于我们测试的 demo 环境,大可不必要安装标准 k8s,就可以用到几乎所有 k8s 的功能和特性.这就让他适用于很多的边缘计算场景.Edge,IoT,Development....等等~

## **什么是 K3S**

K3s 是一个完全兼容的 Kubernetes 发行版，具有以下增强功能：

- 打包为单个二进制文件。
- 使用基于 sqlite3 作为默认存储机制的轻量级存储后端。同时支持使用 etcd3、MySQL 和 Postgres。
- 封装在简单的启动程序中，可以处理很多复杂的 TLS 和选项。
- 默认情况下是安全的，对轻量级环境有合理的默认值。
- 添加了简单但强大的 `batteries-included` 功能，例如

  功能，例如：

  - 本地存储提供程序
  - service load balancer
  - Helm controller
  - Traefik ingress controller

- 所有 Kubernetes control plane 组件的操作都封装在单个二进制文件和进程中。因此，K3s 支持自动化和管理复杂的集群操作（例如证书分发等）。

- 最大程度减轻了外部依赖性，K3s 仅需要现代内核和 cgroup 挂载。K3s 打包了所需的依赖，包括：

  - containerd
  - Flannel (CNI)
  - CoreDNS
  - Traefik (Ingress)
  - Klipper-lb (Service LB)
  - 嵌入式网络策略控制器
  - 嵌入式 local-path-provisioner
  - 主机实用程序（iptables、socat 等）
  
    

## **基础环境**

!!! info 环境要求
    - 如果要使用 docker 做为容器运行时,需要提前预安装docker环境.对于 docker,在 k3s 官方上有一键安装脚本.


一键安装docker脚本：
```
curl https://releases.rancher.com/install-docker/20.10.sh | sh
```




## 单Master节点集群


## **部署 k3s 集群**
!!! warning
    k3s默认使用的运行时是 containerd,--docker 是配置docker作为容器运行时


- 默认安装：（默认是只安装最新版）

```
curl -sfL https://get.k3s.io | sh -s - --docker
```

- 指定安装：INSTALL_K3S_VERSION=v1.22.5+k3s1

```
INSTALL_K3S_VERSION=v1.22.5+k3s1
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.22.5+k3s1 sh -s - --docker
```

## **k3s部署agent端 **

先在server端拿到token：
```shell
root@ubuntu:~# cat /var/lib/rancher/k3s/server/node-token
K10c549fbf4c0197251998eff2e9f451222f297839d4c9150543e6b1b7935a46936::server:588e0646787eb8610efd7b9c1e9fcef0
```

默认安装：（默认是只安装最新版）
```shell
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.0.202:6443 K3S_TOKEN=K10c549fbf4c0197251998eff2e9f451222f297839d4c9150543e6b1b7935a46936::server:588e0646787eb8610efd7b9c1e9fcef0  INSTALL_K3S_EXEC="--docker"  sh -
```

指定安装：
```
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_VERSION=v1.22.5+k3s1 INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.0.202:6443 K3S_TOKEN=K10e3cfbb8fc176b66cb7957997cd7d01958fbbdd507d3c49b75ff819cd0a93905b::server:cba4412e36cc16e5a92137bf987d575d  INSTALL_K3S_EXEC="--docker"  sh -
```




## **高可用k3s集群**

单服务器集群可以满足各种用例，但如果你的环境对 Kubernetes control plane 的正常运行时间有要求，你可以在 HA 配置中运行 K3s。一个高可用 K3s 集群包括：

- 三个或多个 Server 节点为 Kubernetes API 提供服务并运行其他 control plane 服务
- 嵌入式 etcd 数据存储（与单节点设置中使用的嵌入式 SQLite 数据存储相反）

如下图所示: (使用内嵌 etcd 作为存储)

- 我们可以使用 Ucloud 或者其他云的 ulb 作为负载均衡,在创建三台机器作为 k3s-server,一台机器作为 k3s-agent

![20231010142750](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231010142750.png)


### **环境准备:**

-  ucloud 的内网 ulb 是需要在每台 master 做额外的设置的

步骤:
- 需要在每台机器下增加文件 /etc/netplan/lo-cloud-init.yaml，其中 `$VIP` 为 ulb 的内网 IP

```
network:
    ethernets:
        lo:
            addresses:
            - $VIP/32
```

- 执行命令 sudo netplan apply

通过命令 ip a 可以看到 lo 的网卡已经增加了 $VIP。如果没有生效可以尝试重启试试.


!!! warning "温馨提示"
    k3s 默认使用的容器运行时是 containerd,我不太习惯,仍然使用 docker 作为容器运行时.

    - 可以使用: `curl https://releases.rancher.com/install-docker/20.10.sh | sh`


### **高可用部署:**

- 创建一个 master 节点
- 然后将后续的两个 master 加入到集群
- 最后加入 work 节点,加入节点的时候就需要指定 ulb 的ip 了

第一步: master0 需要执行:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_MIRROR=cn sh -s - server -c /home/lixie/master0-config.yaml
```

采用了 k3s server 下一个 -c 的参数，这个参数可以将命令参数以 yaml 的形式传进来

其中`master0-config.yaml`如下所示
   
```
root@10-0-0-118:/home/lixie# cat master0-config.yaml
write-kubeconfig-mode: "0644"
tls-san:
- 10.0.0.118    # m1.k3s.k3s.in.openbayes.com m1.k3s
- 10.0.0.182    # m2.k3s.k3s.in.openbayes.com m2.k3s
- 10.0.0.106    # m3.k3s.k3s.in.openbayes.com m3.k3s
- 10.0.0.150    # node1.k3s.k3s.in.openbayes.com node1.k3s
- 10.0.0.46
- 106.75.6.119
- 106.75.8.51
- 106.75.77.106
docker: true
cluster-init: true
token: VNVIyKGNPtSKTfhi
disable: servicelb
```


**文件说明:**

- 把所有 master 的内网和外网 ip 都放进了 tls-san 同时把内网负载均衡节点 ip 也放了进来。
- k3s 默认使用 containerd 作为容器运行环境，不过我还是用惯了 docker 所以添加了参数 docker: true。
- 第一台 master 采用 cluster-init 的方式启动。
- token 就是一个随机字符串，后面添加 master 节点和 worker 节点只要保持一致就好。
- disable 参数关掉了 k3s 默认添加的 servicelb 如果想要同时关掉 traefik 就可以写成 disable: servicelb,traefik；注意 像配置 tls-san 那样用 yaml 的数组的语法是不行的，这也是让我多花了点时间的地方。


等 master0 的命令执行成功后输入命令 k3s kubectl get nodes -w 等待第一个节点准备完毕后在第二台 master 执行如下命令：

```
curl -sfL https://get.k3s.io | INSTALL_K3S_MIRROR=cn sh -s - server -c /home/lixie/master-others.config.yaml
```

其中 `master-others.config.yaml` 内容如下：
```
root@10-0-0-182:/home/lixie# cat master-others.config.yaml
write-kubeconfig-mode: "0644"
tls-san:
- 10.0.0.118    # m1.k3s.k3s.in.openbayes.com m1.k3s
- 10.0.0.182    # m2.k3s.k3s.in.openbayes.com m2.k3s
- 10.0.0.106    # m3.k3s.k3s.in.openbayes.com m3.k3s
- 10.0.0.150    # node1.k3s.k3s.in.openbayes.com node1.k3s
- 10.0.0.46     # ULB
- 106.75.6.119
- 106.75.8.51
- 106.75.77.106
docker: true
server: https://10.0.0.118:6443
token: VNVIyKGNPtSKTfhi
disable: servicelb
```

Node 节点加入集群:

```shell
curl -sfL https://get.k3s.io \
| K3S_TOKEN=VNVIyKGNPtSKTfhi sh -s - agent --server https://10.0.0.118:6443
```

在 node 节点,拿 master 的 kubeconfig 配置,地址直到 ULB 测试

```
root@10-0-0-150:/home/lixie# kubectl get nodes
NAME         STATUS   ROLES                       AGE    VERSION
10-0-0-106   Ready    control-plane,etcd,master   137m   v1.27.6+k3s1
10-0-0-118   Ready    control-plane,etcd,master   170m   v1.27.6+k3s1
10-0-0-150   Ready    <none>                      12s    v1.27.6+k3s1
10-0-0-182   Ready    control-plane,etcd,master   138m   v1.27.6+k3s1
```





### **卸载k3s**
这里可以通过[k3s](https://docs.rancher.cn/docs/k3s/installation/uninstall/_index)官方方式删除



!!! tip "卸载 k3s"
    ```
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.23.10+k3s1 sh -s - --docker
    ```


### 参考文章
- https://docs.rancher.cn/docs/k3s/quick-start/_index
- https://aisensiy.me/k3s-ha-in-cloud/