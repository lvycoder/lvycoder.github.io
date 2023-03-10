## Master节点维护

1. 首先需要从负载均衡踢出去

2. 将master节点设置不可调度的状态，并驱逐所在节点的pod，这里可能会遇到有些pod无法驱逐的情况，可以强制驱逐

3. 去GitHub下载要升级的二进制包，并进行替换（替换前master需要把服务都停掉）




## 组件升级


- Master节点服务:

  kube-apiserver,kube-controller-manager,kubelet,kube-proxy,kube-scheduler,kubectl 
                                               

- Node节点服务:

  kubectl,kubelet,kube-proxy                  
    

!!! info "kubernetes二进制包如何获取？"
    - https://github.com/kubernetes/kubernetes/releases
    - 选择kubernetes版本，点击CHANGELOG
    - https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.22.md 选择要下载的包
    - wget https://dl.k8s.io/v1.22.17/kubernetes.tar.gz
    - wget https://dl.k8s.io/v1.22.17/kubernetes-client-linux-amd64.tar.gz
    - wget https://dl.k8s.io/v1.22.17/kubernetes-server-linux-amd64.tar.gz
    - wget https://dl.k8s.io/v1.22.17/kubernetes-node-linux-amd64.tar.gz



