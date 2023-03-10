# **k8s 版本升级**
!!! 注意
    请注意以下升级是kubeadm安装的k8s噢

## **版本需求**
k8s 的 版本为v1.19.16，如果要升级到v1.23.8
!!! warning
    注意： 升级不能横跨两个大版本,因此需要升级分4次进行升级，需要1.20.15--1.21.14--1.22.11--1.23.8 （升级四次）


所有节点执行：apt update  


## **主节点:**
```shell

[ucloud] root@master0:~# apt-cache policy kubeadm | grep 1.20.
     1.20.15-00 500
     

# ************所有节点，master和node节点都需要升级*********
apt-get install kubeadm=1.20.15-00

# 查看k8s版本需要的镜像
kubeadm config images list  --kubernetes-version v1.20.15

# 验证升级计划
$ kubeadm upgrade plan
# 看到如下信息，可升级到指定版本

# 看etcd版本是否发生变化

# 主节点升级，如果不需要升级etcd，添加# --etcd-upgrade=false 参数忽略即可
kubeadm upgrade apply v1.20.15
```
注意：
   这时我们发现k8s的版本还是没有变化，更新kubelet。

主节点：
```shell
apt install -y kubelet=1.20.15-00 kubectl=1.20.15-00
```

!!! error
    这种情况可能是之前升级没有进行node节点的kubeadm升级导致的.
    ```
    [sjtu] root@master:/home/lixie# kubeadm upgrade plan
    [upgrade/config] Making sure the configuration is correct:
    [upgrade/config] Reading configuration from the cluster...
    [upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
    [preflight] Running pre-flight checks.
    [upgrade] Running cluster health checks
    [upgrade/health] FATAL: [preflight] Some fatal errors occurred:
        [ERROR ControlPlaneNodesReady]: there are NotReady control-planes in the cluster: [master]
    [preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
    To see the stack trace of this error execute with --v=5 or higher
    ```
解决：（重新安装该版本kubelet和kubectl）
```
apt install kubelet=1.19.16-00
apt install kubectl=1.19.16-00
```


## **从节点:**

1. node节点升级kubelet的配置（所有node节点）

```shell
sudo kubeadm upgrade node
```

2. 安装kubelet和kubectl

```shell
apt install -y kubelet=1.20.15-00 kubectl=1.20.15-00

kubelet --version  # 查看版本
Kubernetes v1.23.8
```


#### 附件

#### k8s证书过期处理
  - 问题：[处理k8s证书过期](https://aisensiy.me/kubernetes-certs-renew)