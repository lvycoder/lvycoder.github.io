## kubeadm + keepalived实现高可用

### 环境准备:
kubernetes 高可用最少需要三台机器，分别在三台机器上部署keepalived服务，优先级为100，80，70。

注意事项: 云环境配置keepalived服务，需要单独开一个VIP。并且keepalived需要开启单播模式
例如: (ucloud云环境)
![image](https://user-images.githubusercontent.com/90956796/223345867-5efb8a3b-a1bd-491e-8791-cae0a66c07af.png)

这里我们申请的VIP地址为：10.0.0.163

所以三台master节点hosts加入一下信息
```
10.0.0.163       ucloud.k8s.vip k8s-vip
```


主机一: m1.ucloud
```
apt install keepalived -y           # 安装keeplived服务

[ucloud] root@master0:~# cat /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 1
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 10.0.0.134       #配置单播的源地址
    unicast_peer {
    10.0.0.57
    10.0.0.8                       #配置单播的目标地址
    }
    virtual_ipaddress {
        10.0.0.163
    }
}
```
主机二: m2.ucloud

```
[ucloud] root@node1:~# cat /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 1
    priority 80
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 10.0.0.57
    unicast_peer {
    10.0.0.134
    10.0.0.8                     #配置单播的目标地址
    }
    virtual_ipaddress {
        10.0.0.163
    }
}
```

主机二: m3.ucloud

```
[ucloud] root@node2:~# cat /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 1
    priority 70
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    unicast_src_ip 10.0.0.8   
    unicast_peer {
    10.0.0.134
    10.0.0.57                    
    }
    virtual_ipaddress {
        10.0.0.163
    }
}
```

## Ansible 系统初始化+部署kubernetes

ansible 跑过kubernetes之后，进行kubernetes 的Master初始化

下面是一个初始化kubeadm的Yaml
```
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "10.0.0.134"
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: "master0"
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: "v1.22.17"
apiServer:
  timeoutForControlPlane: 4m0s
  certSANs:
  - k8s
  - k8s-api
  - "k8s-vip"    //  添加内容
  - "ucloud.k8s.vip"   //  添加内容
  - "master0"
  - "master0.ucloud.in.openbayes.com"
  - "master.ucloud.in.openbayes.com"
  - "106.75.85.160"
certificatesDir: /etc/kubernetes/pki
clusterName: "ucloud"
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
networking:
  dnsDomain: "ucloud.in.openbayes.com"
  podSubnet: "10.96.0.0/20"
  serviceSubnet: "10.97.0.0/20"
controlPlaneEndpoint: "ucloud.k8s.vip:6443"  //  添加内容
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
clusterCIDR: "10.96.0.0/20"
mode: ipvs

# Ansible managed
# vim: ft=yaml:
#
# kubeadm init --config=kubeadm.yaml
```

官方提供了两个shell脚本来拷贝证书

```
[ucloud] root@master0:~# cat scp-ca.sh
USER=ubuntu # 可定制
CONTROL_PLANE_IPS="10.0.0.57"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    # 如果你正使用外部 etcd，忽略下一行
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
done
```

```
[ucloud] root@node2:~# cat cp-ca.sh
USER=ubuntu # 可定制
mkdir -p /etc/kubernetes/pki/etcd
mv /home/${USER}/ca.crt /etc/kubernetes/pki/
mv /home/${USER}/ca.key /etc/kubernetes/pki/
mv /home/${USER}/sa.pub /etc/kubernetes/pki/
mv /home/${USER}/sa.key /etc/kubernetes/pki/
mv /home/${USER}/front-proxy-ca.crt /etc/kubernetes/pki/
mv /home/${USER}/front-proxy-ca.key /etc/kubernetes/pki/
mv /home/${USER}/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt
# 如果你正使用外部 etcd，忽略下一行
mv /home/${USER}/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key
```

初始化Master节点
kubeadm init --config=kubeadm.yaml
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

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join cloud.k8s.vip:6443 --token xy3gsl.dq2o7hriq4n5ujvs \
	--discovery-token-ca-cert-hash sha256:cb5fd12da0f6fbe1202d833e0e197b70f8e08c4d8cfca91c513a6ef8f6ae2efa \
	--control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join cloud.k8s.vip:6443 --token xy3gsl.dq2o7hriq4n5ujvs \
	--discovery-token-ca-cert-hash sha256:cb5fd12da0f6fbe1202d833e0e197b70f8e08c4d8cfca91c513a6ef8f6ae2efa
```

拷贝完成之后，就可以加入master节点了。这样三个节点的高可用也就完成了

