前面我们可以利用ansible自动化搭建了 Kubernetes 集群，接下来我们就可以正式开始学习 Kubernetes 的使用了，在这之前我们还需要先了解下 YAML 文件。

要在 K8s 集群里面运行我们自己的应用，首先我们需要知道几个概念。

第一个当然就是应用的镜像，因为我们在集群中运行的是容器，所以首先需要将我们的应用打包成镜像。镜像准备好了，Kubernetes 集群也准备好了，其实就可以把我们的应用部署到集群中了。但是镜像到集群中运行这个过程如何完成呢？必然有一个地方可以来描述我们的应用，然后把这份描述告诉集群，然后集群按照这个描述来部署应用。

在 Docker 环境下面我们是直接通过命令 docker run 来运行我们的应用的，在 Kubernetes 环境下面我们同样也可以用类似 kubectl run 这样的命令来运行我们的应用，但是在 Kubernetes 中却是不推荐使用命令行的方式，而是希望使用我们称为资源清单的东西来描述应用，资源清单可以用 YAML 或者 JSON 文件来编写，一般来说 YAML 文件更方便阅读和理解，所以我们的课程中都会使用 YAML 文件来进行描述。

通过一个资源清单文件来定义好一个应用后，我们就可以通过 kubectl 工具来直接运行它：


```
kubectl create -f xxxx.yaml
# 或者
kubectl apply -f xxxx.yaml
```

## **第一个容器化应用**

以下这个nginx-deploy的yaml为例子

```yaml
apiVersion: apps/v1 # API版本
kind: Deployment # API对象类型
metadata:
  name: nginx-deploy
  namespace: default
  labels:
    chapter: first-app
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # Pod 副本数量
  template: # Pod 模板
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.7.9
          ports:
            - containerPort: 80
```
然后应用该yaml文件

```
k apply -f nginx-deploy.yaml
```

!!! warning "常用命令"
    - k scale deployment traefik --replicas=3 //调整副本
    - k edit deploy traefik // 编辑yaml
    - k describe pod pod-xxxx // 查看pod详细信息
    - k get pod pod-xxx -o yaml // 查看pod yaml信息
    - k get deploy // 查看deploy 资源
    - k get pod -o wide // 查看pod详情



## **Yaml 文件**

略......










## **文章参考**

- [pod 基础概念学习资料](https://www.yuque.com/cnych/k8s4/vflh8hmhgw1foyeu)
- [一大堆 kubeconfig yaml 维护实践](https://barry-boy.github.io/site/Macuse/mac-kubeconfig/)
- [利用k9s来管理kubernetes集群](https://barry-boy.github.io/site/Macuse/mac-k9s-doc/)