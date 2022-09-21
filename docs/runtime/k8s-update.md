# 上海交大k8s升级：（kubeadm 安装）
> https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/


通过命令我们发现此时k8s的版本为v1.19.16，我打算从v1.19.16升级到v1.23.8，（最后一个支持docker的版本），由于升级不能横跨两个大版本。所以需要通过 v1.19-v1.20-v1.21-v1.22-1.23四次升级升到指定版本。

```
[sjtu] root@master:/home/lixie# kubectl  get nodes  
NAME     STATUS   ROLES              AGE    VERSION
master   Ready    ingress,master     713d   v1.19.16
node1    Ready    gpu,storage,user   713d   v1.19.16
node2    Ready    gpu,storage,user   713d   v1.19.16
node3    Ready    gpu,storage,user   713d   v1.19.16
```


## 升级kubeadm（所有节点）

```
apt update

[ucloud] root@master0:~# apt-cache policy kubeadm | grep 1.20.
     1.20.15-00 500        # 注意这边升级的话需要升到所属版本的最高小版本

apt-get install kubeadm=1.20.15-00      # 所有节点
```
> 如果这边节点过多也可以使用ansible批量执行

```yaml
  tasks:
#  - name: apt kubeadm
#    shell: apt-get install kubeadm=1.23.8-00
```

执行ansible-playbook：
```shell
ansible-playbook  -i inventory/sjtu sjtu.yaml
```

### 查看镜像版本

```shell
kubeadm config images list  --kubernetes-version v1.20.15
```
所有节点都准备好之后，先进行升级master节点

```shell
# 验证升级计划
$ kubeadm upgrade plan   # 看到如下信息，可升级到指定版本

# 看etcd版本是否发生变化
kubeadm upgrade apply v1.20.9 
```
> 如果不需要升级etcd，可以添加 --etcd-upgrade=false  


## 升级kubelet（所有节点)
升级完成发现版本没有变化，需要升级kubelet
```shell
 apt install -y kubelet=1.20.15-00 kubectl=1.20.15-00
```

## node节点

### 升级kubelet的配置

```shell
sudo kubeadm upgrade node
apt install -y kubelet=1.20.15-00 kubectl=1.20.15-00
```

###  校验kubelet版本

```
[ucloud] root@node0:/home/lixie# kubelet --version
Kubernetes v1.23.8
```
