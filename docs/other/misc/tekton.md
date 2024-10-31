# Tekton

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/devops/tekton/overview.md "编辑此页")

# Tekton

[Tekton](https://tekton.dev/) 是一款功能非常强大而灵活的 CI/CD 开源的云原生框架。Tekton 的前身是 Knative 项目的 build-pipeline 项目，这个项目是为了给 build 模块增加 pipeline 的功能，但是随着不同的功能加入到 Knative build 模块中，build 模块越来越变得像一个通用的 CI/CD 系统，于是，索性将 build-pipeline 剥离出 Knative，就变成了现在的 Tekton，而 Tekton 也从此致力于提供全功能、标准化的云原生 CI/CD 解决方案。

![Tekton](https://picdn.youdianzhishi.com/images/1658042117838.png)

Tekton 为 CI/CD 系统提供了诸多好处：

  * **可定制** ：Tekton 是完全可定制的，具有高度的灵活性，我们可以定义非常详细的构建块目录，供开发人员在各种场景中使用。
  * **可重复使用** ：Tekton 是完全可移植的，任何人都可以使用给定的流水线并重用其构建块，可以使得开发人员无需"造轮子"就可以快速构建复杂的流水线。
  * **可扩展** ：`Tekton Catalog` 是社区驱动的 Tekton 构建块存储库，我们可以使用 `Tekton Catalog` 中定义的组件快速创建新的流水线并扩展现有管道。
  * **标准化** ：Tekton 在你的 Kubernetes 集群上作为扩展安装和运行，并使用完善的 Kubernetes 资源模型，Tekton 工作负载在 Kubernetes Pod 内执行。
  * **伸缩性** ：要增加工作负载容量，只需添加新的节点到集群即可，Tekton 可随集群扩展，无需重新定义资源分配或对管道进行任何其他修改。



## 组件

Tekton 由一些列组件组成：

  * `Tekton Pipelines` 是 Tekton 的基础，它定义了一组 Kubernetes CRD 作为构建块，我们可以使用这些对象来组装 CI/CD 流水线。
  * `Tekton Triggers` 允许我们根据事件来实例化流水线，例如，可以我们在每次将 PR 合并到 GitHub 仓库的时候触发流水线实例和构建工作。
  * `Tekton CLI` 提供了一个名为 `tkn` 的命令行界面，它构建在 Kubernetes CLI 之上，运行和 Tekton 进行交互。
  * `Tekton Dashboard` 是 `Tekton Pipelines` 的基于 Web 的一个图形界面，可以线上有关流水线执行的相关信息。
  * `Tekton Catalog` 是一个由社区贡献的高质量 Tekton 构建块（任务、流水线等）存储库，可以直接在我们自己的流水线中使用这些构建块。
  * `Tekton Hub` 是一个用于访问 `Tekton Catalog` 的 Web 图形界面工具。
  * `Tekton Operator` 是一个 Kubernetes Operator，可以让我们在 Kubernetes 集群上安装、更新、删除 Tekton 项目。



## 安装

安装 Tekton 非常简单，可以直接通过 [tektoncd/pipeline](https://github.com/tektoncd/pipeline) 的 GitHub 仓库中的 `release.yaml` 文件进行安装，如下所示的命令：
    
    
    $ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.24.1/release.yaml
    

由于官方使用的镜像是 `gcr` 的镜像，所以正常情况下我们是获取不到的，如果你的集群由于某些原因获取不到镜像，可以使用下面的资源清单文件，我已经将镜像替换成了 Docker Hub 上面的镜像：
    
    
    $ kubectl apply -f https://my-oss-testing.oss-cn-beijing.aliyuncs.com/k8s/tekton/release.v0.37.2.yml
    

上面的资源清单文件安装后，会创建一个名为 `tekton-pipelines` 的命名空间，在该命名空间下面会有大量和 tekton 相关的资源对象，我们可以通过在该命名空间中查看 Pod 并确保它们处于 Running 状态来检查安装是否成功：
    
    
    $ kubectl get pods -n tekton-pipelines
    NAME                                           READY   STATUS              RESTARTS   AGE
    tekton-pipelines-controller-59745c8bd6-nzzqb   1/1     Running             0          44s
    tekton-pipelines-webhook-687fb7945b-p4xnp      0/1     Running             0          11m
    

Tekton 安装完成后，我们还可以选择是否安装 CLI 工具，有时候可能 Tekton 提供的命令行工具比 kubectl 管理这些资源更加方便，当然这并不是强制的，我这里是 Mac 系统，所以可以使用常用的 Homebrew 工具来安装：
    
    
    $ brew tap tektoncd/tools
    $ brew install tektoncd/tools/tektoncd-cli
    

安装完成后可以通过如下命令验证 CLI 是否安装成功：
    
    
    $ tkn version
    Client version: 0.24.0
    Pipeline version: v0.37.2
    Dashboard version: v0.28.0
    

还可以从 [tknReleases](https://github.com/tektoncd/cli/releases) 页面下载安装包，下载文件后，将其解压缩到您的 PATH：
    
    
    $ wget https://github.91chi.fun/https://github.com//tektoncd/cli/releases/download/v0.24.0/tkn_0.24.0_Darwin_all.tar.gz
    $ tar -xvf tkn_0.24.0_Darwin_all.tar.gz
    $ chmod +x tkn
    $ sudo mv tkn /usr/local/bin
    

此外，还可以安装一个 Tekton 提供的一个 Dashboard，我们可以通过 Dashboard 查看 Tekton 整个任务的构建过程，直接执行下面的命令直接安装即可：
    
    
    $ kubectl apply -f https://my-oss-testing.oss-cn-beijing.aliyuncs.com/k8s/tekton/dashboard.v0.28.0.yml
    

安装完成后我们可以修改 Dashboard 的 Service 为 NodePort 来访问应用，或者添加一个 Ingress 对象来对外暴露：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: tekton-dashboard
      namespace: tekton-pipelines
    spec:
      ingressClassName: nginx # 使用 nginx 的 IngressClass（关联的 ingress-nginx 控制器）
      rules:
        - host: tekton.k8s.local
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: tekton-dashboard
                    port:
                      number: 9097
    

创建上面的对象后将 `tekton.k8s.local` 解析到 Ingress 控制器的入口地址，然后就可以通过该地址访问到 Tekton 的 Dashboard 了。

![tekton dashboard](https://picdn.youdianzhishi.com/images/1658045817748.png)

## 概念

Tekton 为 Kubernetes 提供了多种 CRD 资源对象，可用于定义我们的流水线。

![tekton 对象](https://picdn.youdianzhishi.com/images/20210608211119.png)

主要有以下几个资源对象：

  * **Task** ：表示执行命令的一系列有序的步骤，task 里可以定义一系列的 steps，例如编译代码、构建镜像、推送镜像等，每个 task 实际由一个 Pod 执行。
  * **TaskRun** ：Task 只是定义了一个模版，TaskRun 才真正代表了一次实际的运行，当然你也可以自己手动创建一个 TaskRun，TaskRun 创建出来之后，就会自动触发 Task 描述的构建任务。
  * **Pipeline** ：一组有序的 Task，Pipeline 中的 Task 可以使用之前执行过的 Task 的输出作为它的输入。表示一个或多个 Task、PipelineResource 以及各种定义参数的集合。
  * **PipelineRun** ：类似 Task 和 TaskRun 的关系，`PipelineRun` 也表示某一次实际运行的 pipeline，下发一个 PipelineRun CRD 实例到 Kubernetes 后，同样也会触发一次 pipeline 的构建。
  * **ClusterTask** ：覆盖整个集群的任务，而不是单一的某一个命名空间，这是和 Task 最大的区别，其他基本上一致的。
  * **PipelineResource** （Deprecated）：定义由 `Tasks` 中的步骤摄取的输入和产生的输出的位置，比如 github 上的源码，或者 pipeline 输出资源，例如一个容器镜像或者构建生成的 jar 包等。
  * **Run** （alpha）：实例化自定义任务以在特定输入时执行。



每个任务都在自己的 Kubernetes Pod 中执行，因此，默认情况下，管道内的任务不共享数据。要在 Tasks 之间共享数据，你必须明确配置每个 Task 以使其输出可用于下一个 Task 并获取先前执行的 Task 的输出作为其输入。
