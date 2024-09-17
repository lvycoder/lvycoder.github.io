# **k8s 简介**
    
  - 开源容器化编排引擎，专用于管理容器化应用和服务集群。

## **核心组件介绍**

### **控制平面组件**

!!! info "kube-apiserver:"

**官方解释:** 
    
- API 服务器是 Kubernetes 控制平面的组件， 该组件负责公开了 Kubernetes API，负责处理接受请求的工作。 API 服务器是 Kubernetes 控制平面的前端。
- Kubernetes API 服务器的主要实现是 kube-apiserver。 kube-apiserver 设计上考虑了水平扩缩，也就是说，它可通过部署多个实例来进行扩缩。 你可以运行 kube-apiserver 的多个实例，并在这些实例之间平衡流量。

**个人理解:**

- k8s的访问入口，如果想操作容器，必须要通过api-server才可以。k8s集群所有的node都要与api-server进行通信，所以node的数量越多给api-server的压力就会越大。所以一般k8s-master都是集群来高可用的，通常来说都是三个节点。


!!! info "kube-scheduler:"

**官方解释:**

- 是负责资源调度的进程，监视新创建且没有分配到Node的Pod，为Pod 选择一个Node；
- 调度决策考虑的因素包括单个 Pod 及 Pods 集合的资源需求、`软硬件及策略约束、 亲和性及反亲和性规范、数据位置、工作负载间的干扰及最后时限`.

**个人理解:**

- 管理员发送创建一个容器的指令到api-server，api-server收到这个指令就存储在etcd中，kube-scheduler会监听api-server看看有没有pod的操作事件，如果没有下次接着查询，如果有的话，kube-scheduler会通过api-server拿到etcd这个事件。然后kube-scheduler会根据node的资源利用率来进行调度。调度之后kube-scheduler会把结果返回给api-server，api-server再把结果写到etcd。






!!! info "kube-controller-manager:"

**官方解释:**

- 运行管理控制器，是集群中处理常规任务的后台进程，是Kubernetes 里所有资源对象的自动化控制中心。逻辑上，每个控制器是一个单独的进程，但为了降低复杂性，它们都被编译成单个二进制文件，并在单个进程中运行。这些控制器主要包括。

- 节点控制器（Node Controller）：负责在Node节点出现故障时及时发现和响应；
- 复制控制器（Replication Controller）：负责维护正确数量的Pod；
- 端点控制器（Endpoints Controller）：填充端点对象（即连接Services和Pods）；
- 服务帐户和令牌控制器（Service Account & Token Controllers）：为新的命名空间创建默认帐户和API访问令牌。

**个人理解:**

!!! info "etcd:"

**官方解释:**

- 是Kubernetes 提供的默认存储，所有集群数据都保存在Etcd中，使用时建议为Etcd 数据提供备份计划；

**个人理解:**

- 一堆控制器（副本控制器，节点控制器，命令空间控制器，服务器账号控制器等），控制器做为集群内部管理控制中心，负责集群内的node、pod、服务端点、命名空间、服务器账号，资源定额的管理，当某个node意外宕机，Controller-manager会自动发现并执行自动恢复流程。确保集群中pod的副本始终保持预期工作的状态。


### **Node 组件**


!!! info "kubelet："

**官方解释:**

- 负责Pod对应容器的创建、起停等任务，同时与Master 节点密切协作，实现集群管理的基本功能。

**个人理解:**

- kubelet是维护node上pod的状态，如果pod挂了，他会将事件发送给api-server，api-server将事件写入etcd，kube-scheduler或者Controller-manager会拿到api-server上的事件，对pod进行重建等操作。

!!! info "kube-proxy："
**官方解释:**

- 官网解释：集群中每个节点上运行的网络代理， 实现 Kubernetes 服务（Service） 概念的一部分

**个人理解:**

- 个人理解：维护当前主机的网络规则


### **其他组件**

helm install mysql presslabs/mysql-operator \
    -f 1-config.yaml \
    -n infra 

    helm install mysql-operator bitpoke/mysql-operator \
    -f 1-config.yaml \
    -n infra