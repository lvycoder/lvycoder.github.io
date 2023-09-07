# k8s集群部署

## kubeadm 创建集群

!!! tip "注意以下是centos搭建"


### 集群初始化
```shell
# 将 SELinux 设置为 permissive 模式（相当于将其禁用）
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#关闭swap
swapoff -a  
sed -ri 's/.*swap.*/#&/' /etc/fstab

#允许 iptables 检查桥接流量
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

安装kubelet、kubeadm、kubectl
```shell
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
   http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet-1.20.9 kubeadm-1.20.9 kubectl-1.20.9 --disableexcludes=kubernetes

# 所有节点

sudo systemctl enable --now kubelet

```

!!! info "温馨提示"
    - kubelet 现在每隔几秒就会重启，因为它陷入了一个等待 kubeadm 指令的死循环

查看kubeadm的版本，并拉取该版本的images

```
kubeadm config images list  --kubernetes-version v1.20.9 > k8s.images

root@ubuntu:/home/ubuntu/script# cat k8s.images |awk -F'/' '{print $2}'
kube-apiserver:v1.20.9
kube-controller-manager:v1.20.9
kube-scheduler:v1.20.9
kube-proxy:v1.20.9
pause:3.2
etcd:3.4.13-0
coredns:1.7.0
```
脚本下载镜像
```
root@ubuntu:/home/ubuntu/script# cat ubuntu-k8s-images.sh
#!/bin/bash
images='
kube-apiserver:v1.20.9
kube-controller-manager:v1.20.9
kube-scheduler:v1.20.9
kube-proxy:v1.20.9
pause:3.2
etcd:3.4.13-0
coredns:1.7.0
'

for i in $images ; do
docker pull registry.aliyuncs.com/google_containers/$i
done
```

初始化master节点：
```
#所有机器添加master域名映射，以下需要修改为自己的
echo "192.168.8.70  cluster-endpoint" >> /etc/hosts



# 主节点初始化
kubeadm init \
--apiserver-advertise-address=192.168.159.201 \
--control-plane-endpoint=cluster-endpoint \
--image-repository registry.cn-hangzhou.aliyuncs.com/lfy_k8s_images \
--kubernetes-version v1.20.9 \
--service-cidr=10.96.0.0/16 \
--pod-network-cidr=172.16.0.0/16

#所有网络范围不重叠
```


## 节点初始化

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.11:6443 --token bv4kei.ozbuoivuj8jxaa6q \
	--discovery-token-ca-cert-hash sha256:e37c82f136192e54480555eeaa2a102cec8b630f18b5fffd0e24c1d1c0c8f730
```



初始化发现所有状态都是`NotReady`安装网络组件: [calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart)




### Node节点加入集群
!!! warning 
    - 新令牌,默认的令牌24小时候失效
    kubeadm token create --print-join-command  


### Mac连接集群报错
!!! error "Mac 连接k8s集群报错"
    - x509: certificate signed by unknown authority
    - 创建集群的时候没有执行外网地址.导致证书不能正常使用
    - 将 master 的外网地址和主机名解析到本地 hosts


### 清理k8s集群
!!! success

```
[root@k8s-master ~]# kubeadm reset
[root@k8s-master ~]# kubectl delete node 192.168.200.112

[root@k8s-node01 ~]# docker rm -f $(docker ps -aq)
[root@k8s-node01 ~]# systemctl stop kubelet
[root@k8s-node01 ~]# rm -rf /etc/kubernetes/*
[root@k8s-node01 ~]# rm -rf /var/lib/kubelet/*
```


### 报错解决

在使用k8s的过程中，经常会遇到集群出问题，那么可以通过以下命令来查看kubelet 日志，解决问题。
```shell
[cka] root@node1:/home/lixie# journalctl -u kubelet -f   //绝大部分的错误都需要看日志来解决
```


### 强制删除namespace

!!! info "delete namespace"

```yaml
打开一个新窗口：root@master30:~# kubectl proxy --port=8001
方法二

$ NAMESPACE_NAME=rook-ceph
cat <<EOF | curl -X PUT \
  127.0.0.1:8001/api/v1/namespaces/$NAMESPACE_NAME/finalize \
  -H "Content-Type: application/json" \
  --data-binary @-
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "$NAMESPACE_NAME"
  },
  "spec": {
    "finalizers": null
  }
}
EOF
```



!!! error "System OOM encountered"
    - 两种OOM（进程OOM，容器OOM）发生后，都可能会伴随一个系统OOM事件，该事件的原因是由上述OOM事件伴随导致。
    - 需要解决上面进程OOM或者容器CgroupOOM的问题，文章参考: [解决OOM](https://caryyu.top/posts/%E8%AE%BA%E4%B8%80%E6%AC%A1-K8S-%E7%9A%84-Worker-%E8%8A%82%E7%82%B9%E4%BF%AE%E5%A4%8D%E7%BB%8F%E5%8E%86/)





### 小技巧

!!! info "小技巧"
    - Mac 管理kubernetes，合并yaml 
    - https://aisensiy.me/kubeconfig-management
    - 可以通过journalctl -xeu kubelet 来查看日志


