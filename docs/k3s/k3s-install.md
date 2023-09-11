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


## 卸载k3s
这里可以通过[k3s](https://docs.rancher.cn/docs/k3s/installation/uninstall/_index)官方方式删除



!!! tip "卸载 k3s"
    ```
    curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.23.10+k3s1 sh -s - --docker
    ```

### 参考文章
- https://docs.rancher.cn/docs/k3s/quick-start/_index