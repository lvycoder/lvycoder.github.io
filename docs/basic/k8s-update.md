# **k8s 版本升级**
!!! 注意
   升级k8s集群必须 先升级kubeadm版本到⽬的k8s版本，也就是说kubeadm是k8s升级的准升证。


## **Kubernetes 添加清华源**

### **温馨提示**

- https://mirrors.tuna.tsinghua.edu.cn/help/kubernetes/
- 这里我们使用清华的源，阿里云的源对于kubeadm 的包不齐全


1.首先导入 gpg key：

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

2.新建 `/etc/apt/sources.list.d/kubernetes.list`，内容为

```bash
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] http://mirrors.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/v1.26/deb/ /
```

3.更新 apt
```
apt update
```

## **Master安装指定新版本kubeadm**

```
# kubeadm config images list --config kubeadm.yaml
# kubeadm config images pull --config kubeadm.yaml


kubeadm config images list  --kubernetes-version v1.26.15
kubeadm config images pull --config kubeadm.yaml
kubeadm config images list --config kubeadm.yaml


$ apt-cache madison kubeadm # 查看k8s版本列表
$ apt-cache policy kubeadm | grep 1.26. # 查看k8s版本列表
$ apt-get install kubeadm=1.26.15-1.1

$ kubeadm version # 验证kubeadm 版本
$ kubeadm upgrade plan  # 验证升级计划
$ kubeadm upgrade apply v1.26.15 # 升级
```


## **升级K8s node节点版本:**

```
$ apt-cache policy kubelet
$ kubeadm upgrade node
$ apt update && apt install kubelet=1.26.15-1.1 kubectl=1.26.15-1.1
$ systemctl restart kubelet
```


## **文章参考**

- https://k8s.huweihuang.com/project/etcd/etcdctl/etcdctl-v3