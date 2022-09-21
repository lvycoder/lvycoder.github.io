# Docker 运行时部署k3s

参考地址：https://docs.rancher.cn/docs/k3s/quick-start/_index

## 基础环境

!!! 环境要求
    Lightweight Kubernetes. Easy to install, half the memory, all in a binary of less than 100 MB.

- 时间同步，时区
- 关闭防火墙
- docker环境



!!! 外置环境要求
    - 需要安装docker环境作为容器运行时，默认不是docker.


安装docker：
```
curl https://releases.rancher.com/install-docker/19.03.sh | sh
```

## k3s安装server端
!!! warning
    --docker 是使用docker作为容器运行时

默认安装：（默认是只安装最新版）
```
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -s - --docker
```
指定安装：INSTALL_K3S_VERSION=v1.22.5+k3s1
```
INSTALL_K3S_VERSION=v1.22.5+k3s1
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.22.5+k3s1 sh -s - --docker
```

## k3s部署agent端 

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


## **更新版：**

## k3s安装server端
```
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.22.5+k3s1  sh -s - --docker
```



## k3s 部署agent端 

```
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn  INSTALL_K3S_VERSION=v1.22.5+k3s1 K3S_URL=https://192.168.0.202:6443 K3S_TOKEN=K10ab8ec9db721e53cf65e395d44b2b59a48ee1744dcf7c691733f907af47c88630::server:806d6ca499e7ae52c75c89a7f47961b4 sh  -s - --docker
```


## 卸载k3s
这里可以通过[k3s](https://docs.rancher.cn/docs/k3s/installation/uninstall/_index)官方方式删除