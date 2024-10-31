# Argo CD

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/devops/gitops/argocd.md "编辑此页")

# Argo CD

[Argo CD](https://argoproj.github.io/argo-cd) 是一个为 Kubernetes 而生的，遵循声明式 GitOps 理念的持续部署工具。Argo CD 可在 Git 存储库更改时自动同步和部署应用程序。

Argo CD 遵循 GitOps 模式，使用 Git 仓库作为定义所需应用程序状态的真实来源，Argo CD 支持多种 Kubernetes 清单：

  * kustomize
  * helm charts
  * ksonnet applications
  * jsonnet files
  * Plain directory of YAML/json manifests
  * Any custom config management tool configured as a config management plugin



Argo CD 可在指定的目标环境中自动部署所需的应用程序状态，应用程序部署可以在 Git 提交时跟踪对分支、标签的更新，或固定到清单的指定版本。

## 架构

![ArgoCD架构](https://picdn.youdianzhishi.com/images/20210703110614.png)

Argo CD 是通过一个 Kubernetes 控制器来实现的，它持续 watch 正在运行的应用程序并将当前的实时状态与所需的目标状态（ Git 存储库中指定的）进行比较。已经部署的应用程序的实际状态与目标状态有差异，则被认为是 `OutOfSync` 状态，Argo CD 会报告显示这些差异，同时提供工具来自动或手动将状态同步到期望的目标状态。在 Git 仓库中对期望目标状态所做的任何修改都可以自动应用反馈到指定的目标环境中去。

下面简单介绍下 Argo CD 中的几个主要组件：

**API 服务** ：API 服务是一个 gRPC/REST 服务，它暴露了 Web UI、CLI 和 CI/CD 系统使用的接口，主要有以下几个功能：

  * 应用程序管理和状态报告
  * 执行应用程序操作（例如同步、回滚、用户定义的操作）
  * 存储仓库和集群凭据管理（存储为 K8S Secrets 对象）
  * 认证和授权给外部身份提供者
  * RBAC
  * Git webhook 事件的侦听器/转发器



**仓库服务** ：存储仓库服务是一个内部服务，负责维护保存应用程序清单 Git 仓库的本地缓存。当提供以下输入时，它负责生成并返回 Kubernetes 清单：

  * 存储 URL
  * revision 版本（commit、tag、branch）
  * 应用路径
  * 模板配置：参数、ksonnet 环境、helm values.yaml 等



**应用控制器** ：应用控制器是一个 Kubernetes 控制器，它持续 watch 正在运行的应用程序并将当前的实时状态与所期望的目标状态（ repo 中指定的）进行比较。它检测应用程序的 `OutOfSync` 状态，并采取一些措施来同步状态，它负责调用任何用户定义的生命周期事件的钩子（PreSync、Sync、PostSync）。

## 功能

  * 自动部署应用程序到指定的目标环境
  * 支持多种配置管理/模板工具（Kustomize、Helm、Ksonnet、Jsonnet、plain-YAML）
  * 能够管理和部署到多个集群
  * SSO 集成（OIDC、OAuth2、LDAP、SAML 2.0、GitHub、GitLab、Microsoft、LinkedIn）
  * 用于授权的多租户和 RBAC 策略
  * 回滚/随时回滚到 Git 存储库中提交的任何应用配置
  * 应用资源的健康状况分析
  * 自动配置检测和可视化
  * 自动或手动将应用程序同步到所需状态
  * 提供应用程序活动实时视图的 Web UI
  * 用于自动化和 CI 集成的 CLI
  * Webhook 集成（GitHub、BitBucket、GitLab）
  * 用于自动化的 AccessTokens
  * PreSync、Sync、PostSync Hooks，以支持复杂的应用程序部署（例如蓝/绿和金丝雀发布）
  * 应用程序事件和 API 调用的审计
  * Prometheus 监控指标
  * 用于覆盖 Git 中的 ksonnet/helm 参数



## 核心概念

  * **Application** ：应用，一组由资源清单定义的 Kubernetes 资源，这是一个 CRD 资源对象
  * **Application source type** ：用来构建应用的工具
  * **Target state** ：目标状态，指应用程序所需的期望状态，由 Git 存储库中的文件表示
  * **Live state** ：实时状态，指应用程序实时的状态，比如部署了哪些 Pods 等真实状态
  * **Sync status** ：同步状态表示实时状态是否与目标状态一致，部署的应用是否与 Git 所描述的一样？
  * **Sync** ：同步指将应用程序迁移到其目标状态的过程，比如通过对 Kubernetes 集群应用变更
  * **Sync operation status** ：同步操作状态指的是同步是否成功
  * **Refresh** ：刷新是指将 Git 中的最新代码与实时状态进行比较，弄清楚有什么不同
  * **Health** ：应用程序的健康状况，它是否正常运行？能否为请求提供服务？
  * **Tool** ：工具指从文件目录创建清单的工具，例如 Kustomize 或 Ksonnet 等
  * **Configuration management tool** ：配置管理工具
  * **Configuration management plugin** ：配置管理插件



## 安装

当然前提是需要有一个 kubectl 可访问的 Kubernetes 的集群，直接使用下面的命令即可，这里我们安装最新的稳定版 v2.4.9：
    
    
    $ kubectl create namespace argocd
    $ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.9/manifests/install.yaml
    

如果你要用在生产环境，则可以使用下面的命令部署一个 HA 高可用的版本：
    
    
    $ kubectl create namespace argocd
    $ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.9/manifests/ha/install.yaml
    

这将创建一个新的命名空间 argocd，Argo CD 的服务和应用资源都将部署到该命名空间。
    
    
    $ kubectl get pods -n argocd
    NAME                                                READY   STATUS    RESTARTS   AGE
    argocd-application-controller-0                     1/1     Running   0          103s
    argocd-applicationset-controller-68b9bdbd8b-jzcpf   1/1     Running   0          103s
    argocd-dex-server-6b7745757-6mxwk                   1/1     Running   0          103s
    argocd-notifications-controller-5b56f6f7bb-jqpng    1/1     Running   0          103s
    argocd-redis-f4cdbff57-dr8jc                        1/1     Running   0          103s
    argocd-repo-server-c4f79b4d6-7nh6n                  1/1     Running   0          103s
    argocd-server-895675597-fr42g                       1/1     Running   0          103s
    

> 如果你对 UI、SSO、多集群管理这些特性不感兴趣，只想把应用变更同步到集群中，那么你可以使用 `--disable-auth` 标志来禁用认证，可以通过命令 `kubectl patch deploy argocd-server -n argocd -p '[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--disable-auth"}]' --type json` 来实现。

然后我们可以在本地安装 CLI 工具方便操作 Argo CD，我们可以在 [Argo CD Git 仓库发布页面](https://github.com/argoproj/argo-cd/releases/latest)查看最新版本的 Argo CD 或运行以下命令来获取版本：
    
    
    VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    

`VERSION` 在下面的命令中替换为你要下载的 Argo CD 版本：
    
    
    $ curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
    

为 argocd CLI 赋予可执行权限：
    
    
    $ chmod +x /usr/local/bin/argocd
    

现在我们就可以使用 `argocd` 命令了。如果你是 Mac，则可以直接使用 `brew install argocd` 进行安装。

Argo CD 会运行一个 gRPC 服务（由 CLI 使用）和 HTTP/HTTPS 服务（由 UI 使用），这两种协议都由 `argocd-server` 服务在以下端口进行暴露：

  * 443 - gRPC/HTTPS
  * 80 - HTTP（重定向到 HTTPS）



我们可以通过配置 Ingress 的方式来对外暴露服务，其他 Ingress 控制器的配置可以参考官方文档 <https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/> 进行配置。

Argo CD 在同一端口 (443) 上提供多个协议 (gRPC/HTTPS)，所以当我们为 argocd 服务定义单个 nginx ingress 对象和规则的时候有点麻烦，因为 `nginx.ingress.kubernetes.io/backend -protocol` 这个 annotation 只能接受一个后端协议（例如 HTTP、HTTPS、GRPC、GRPCS）。

为了使用单个 ingress 规则和主机名来暴露 Argo CD APIServer，必须使用 `nginx.ingress.kubernetes.io/ssl-passthrough` 这个 annotation 来传递 TLS 连接并校验 Argo CD APIServer 上的 TLS。
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server-ingress
      namespace: argocd
      annotations:
        nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    spec:
      ingressClassName: nginx
      rules:
        - host: argocd.k8s.local
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      name: https
    

上述规则在 Argo CD APIServer 上校验 TLS，该服务器检测到正在使用的协议，并做出适当的响应。请注意，`nginx.ingress.kubernetes.io/ssl-passthrough` 注解要求将 `--enable-ssl-passthrough` 标志添加到 `nginx-ingress-controller` 的命令行参数中。

由于 `ingress-nginx` 的每个 Ingress 对象仅支持一个协议，因此另一种方法是定义两个 Ingress 对象。一个用于 HTTP/HTTPS，另一个用于 gRPC。

如下所示为 HTTP/HTTPS 的 Ingress 对象：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server-http-ingress
      namespace: argocd
      annotations:
        nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    spec:
      ingressClassName: nginx
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      name: http
          host: argocd.k8s.local
      tls:
        - hosts:
            - argocd.k8s.local
          secretName: argocd-secret # do not change, this is provided by Argo CD
    

gRPC 协议对应的 Ingress 对象如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server-grpc-ingress
      namespace: argocd
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    spec:
      ingressClassName: nginx
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      name: https
          host: grpc.argocd.k8s.local
      tls:
        - hosts:
            - grpc.argocd.k8s.local
          secretName: argocd-secret # do not change, this is provided by Argo CD
    

然后我们需要在禁用 TLS 的情况下运行 APIServer。编辑 argocd-server 这个 Deployment 以将 `--insecure` 标志添加到 argocd-server 命令，或者简单地在 `argocd-cmd-params-cm` ConfigMap 中设置 `server.insecure: "true"` 即可。

创建完成后，我们就可以通过 `argocd.k8s.local` 来访问 Argo CD 服务了，不过需要注意我们这里配置的证书是自签名的，所以在第一次访问的时候会提示不安全，强制跳转即可。

默认情况下 `admin` 帐号的初始密码是自动生成的，会以明文的形式存储在 Argo CD 安装的命名空间中名为 `argocd-initial-admin-secret` 的 Secret 对象下的 `password` 字段下，我们可以用下面的命令来获取：
    
    
    $ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
    

使用用户名 `admin` 和上面输出的密码即可登录 Dashboard。

![argocd ui](https://picdn.youdianzhishi.com/images/1660377764540.png)

同样我们也可以通过 ArgoCD CLI 命令行工具进行登录：
    
    
    $ argocd login grpc.argocd.k8s.local
    WARNING: server certificate had error: x509: “Kubernetes Ingress Controller Fake Certificate” certificate is not trusted. Proceed insecurely (y/n)? y
    Username: admin
    Password:
    'admin:login' logged in successfully
    Context 'grpc.argocd.k8s.local' updated
    

需要注意的是这里登录的地址为 gRPC 暴露的服务地址。

CLI 登录成功后，可以使用如下所示命令更改密码：
    
    
    $ argocd account update-password
    *** Enter current password:
    *** Enter new password:
    *** Confirm new password:
    Password updated
    Context 'argocd.k8s.local' updated
    $ argocd version
    argocd: v2.4.9+1ba9008
      BuildDate: 2022-08-11T15:41:08Z
      GitCommit: 1ba9008536b7e61414784811c431cd8da356065e
      GitTreeState: clean
      GoVersion: go1.18.5
      Compiler: gc
      Platform: darwin/arm64
    argocd-server: v2.4.9+1ba9008
      BuildDate: 2022-08-11T15:22:41Z
      GitCommit: 1ba9008536b7e61414784811c431cd8da356065e
      GitTreeState: clean
      GoVersion: go1.18.5
      Compiler: gc
      Platform: linux/amd64
      Kustomize Version: v4.4.1 2021-11-11T23:36:27Z
      Helm Version: v3.8.1+g5cb9af4
      Kubectl Version: v0.23.1
      Jsonnet Version: v0.18.0
    

## 配置集群

由于 Argo CD 支持部署应用到多集群，所以如果你要将应用部署到外部集群的时候，需要先将外部集群的认证信息注册到 Argo CD 中，如果是在内部部署（运行 Argo CD 的同一个集群，默认不需要配置），直接使用 `https://kubernetes.default.svc` 作为应用的 K8S APIServer 地址即可。

首先列出当前 `kubeconfig` 中的所有集群上下文：
    
    
    $ kubectl config get-contexts -o name
    

从列表中选择一个上下文名称并将其提供给 `argocd cluster add CONTEXTNAME`，比如对于 `kind-kind`上下文，运行：
    
    
    $ argocd cluster add kind-kind
    

## 创建应用

Git 仓库 <https://github.com/argoproj/argocd-example-apps.git> 是一个包含留言簿应用程序的示例库，我们可以用该应用来演示 Argo CD 的工作原理。

### 通过 CLI 创建应用

我们可以通过 `argocd app create xxx` 命令来创建一个应用：
    
    
    $ argocd app create --help
    Create an application
    
    Usage:
      argocd app create APPNAME [flags]
    
    Examples:
    
            # Create a directory app
            argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-namespace default --dest-server https://kubernetes.default.svc --directory-recurse
    
            # Create a Jsonnet app
            argocd app create jsonnet-guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path jsonnet-guestbook --dest-namespace default --dest-server https://kubernetes.default.svc --jsonnet-ext-str replicas=2
    
            # Create a Helm app
            argocd app create helm-guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path helm-guestbook --dest-namespace default --dest-server https://kubernetes.default.svc --helm-set replicaCount=2
    
            # Create a Helm app from a Helm repo
            argocd app create nginx-ingress --repo https://charts.helm.sh/stable --helm-chart nginx-ingress --revision 1.24.3 --dest-namespace default --dest-server https://kubernetes.default.svc
    
            # Create a Kustomize app
            argocd app create kustomize-guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path kustomize-guestbook --dest-namespace default --dest-server https://kubernetes.default.svc --kustomize-image gcr.io/heptio-images/ks-guestbook-demo:0.1
    
            # Create a app using a custom tool:
            argocd app create kasane --repo https://github.com/argoproj/argocd-example-apps.git --path plugins/kasane --dest-namespace default --dest-server https://kubernetes.default.svc --config-management-plugin kasane
    
    
    Flags:
    ......
    

直接执行如下所示命令即可：
    
    
    $ argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
    application 'guestbook' created
    

### 通过 UI 创建应用

除了可以通过 CLI 工具来创建应用，我们也可以通过 UI 界面来创建，定位到 `argocd.k8s.local` 页面，登录后，点击 `+New App` 新建应用按钮，如下图：

![New App](https://picdn.youdianzhishi.com/images/1660378581536.png)

将应用命名为 guestbook，使用 default project，并将同步策略设置为 `Manual`：

![配置应用](https://picdn.youdianzhishi.com/images/1660379051015.jpg)

然后在下面配置 `Repository URL` 为 <https://github.com/argoproj/argocd-example-apps.git>，由于某些原因我们这里使用的是一个 GitHub 仓库加速地址 `https://github.91chi.fun/https://github.com/cnych/argocd-example-apps.git`，将 Revision 设置为 HEAD，并将路径设置为 guestbook。然后下面的 Destination 部分，将 cluster 设置为 `inCluster` 和 namespace 为 default：

![配置集群](https://picdn.youdianzhishi.com/images/1660379593188.png)

填写完以上信息后，点击页面上方的 Create 安装，即可创建 guestbook 应用，创建完成后可以看到当前应用的处于 `OutOfSync` 状态：

![guestbook application](https://picdn.youdianzhishi.com/images/1660379147032.png)

Argo CD 默认情况下每 3 分钟会检测 Git 仓库一次，用于判断应用实际状态是否和 Git 中声明的期望状态一致，如果不一致，状态就转换为 `OutOfSync`。默认情况下并不会触发更新，除非通过 `syncPolicy` 配置了自动同步。

### 通过 CRD 创建

除了可以通过 CLI 和 Dashboard 可以创建 Application 之外，其实也可以直接通过声明一个 `Application` 的资源对象来创建一个应用，如下所示：
    
    
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: guestbook
    spec:
      destination:
        name: ""
        namespace: default
        server: "https://kubernetes.default.svc"
      source:
        path: guestbook
        repoURL: "https://github.com/cnych/argocd-example-apps"
        targetRevision: HEAD
      project: default
      syncPolicy:
        automated: null
    

## 部署应用

由于上面我们在创建应用的时候使用的同步策略为 `Manual`，所以应用创建完成后没有自动部署，需要我们手动去部署应用。同样可以通过 CLI 和 UI 界面两种同步方式。

### 使用 CLI 同步

应用创建完成后，我们可以通过如下所示命令查看其状态：
    
    
    $ argocd app get guestbook
    Name:               guestbook
    Project:            default
    Server:             https://kubernetes.default.svc
    Namespace:          default
    URL:                https://grpc.argocd.k8s.local/applications/guestbook
    Repo:               https://github.91chi.fun/https://github.com/cnych/argocd-example-apps.git
    Target:             HEAD
    Path:               guestbook
    SyncWindow:         Sync Allowed
    Sync Policy:        <none>
    Sync Status:        OutOfSync from HEAD (67bda3d)
    Health Status:      Missing
    
    GROUP  KIND        NAMESPACE  NAME          STATUS     HEALTH   HOOK  MESSAGE
           Service     default    guestbook-ui  OutOfSync  Missing
    apps   Deployment  default    guestbook-ui  OutOfSync  Missing
    

应用程序状态为初始 `OutOfSync` 状态，因为应用程序尚未部署，并且尚未创建任何 Kubernetes 资源。要同步（部署）应用程序，可以执行如下所示命令：
    
    
    $ argocd app sync guestbook
    

此命令从 Git 仓库中检索资源清单并执行 `kubectl apply` 部署应用，执行上面命令后 guestbook 应用便会运行在集群中了，现在我们就可以查看其资源组件、日志、事件和评估其健康状态了。

### 通过 UI 同步

直接添加 UI 界面上应用的 `Sync` 按钮即可开始同步：

![sync 操作](https://picdn.youdianzhishi.com/images/20210703155911.png)

同步完成后可以看到我们的资源状态：

![Sync 完成](https://picdn.youdianzhishi.com/images/1660379760740.png)

甚至还可以直接查看应用的日志信息：

![Sync 完成](https://picdn.youdianzhishi.com/images/1660379818204.png)

也可以通过 kubectl 查看到我们部署的资源：
    
    
    ➜  ~ kubectl get pods
    NAME                                 READY   STATUS      RESTARTS       AGE
    guestbook-ui-6c96fb4bdc-bdwh9        1/1     Running     0              3m3s
    ➜  ~ kubectl get svc
    NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
    guestbook-ui         ClusterIP      10.100.170.117   <none>         80/TCP                       3m16s
    kubernetes           ClusterIP      10.96.0.1        <none>         443/TCP                      42d
    

和我们从 Git 仓库中同步 `guestbook` 目录下面的资源状态也是同步的，证明同步成功了。

![sync status](https://picdn.youdianzhishi.com/images/1660380018340.jpg)

## Tekton 结合 Argo CD

前面我们使用 Tekton 完成了应用的 CI/CD 流程，但是 CD 是在 Tekton 的任务中去完成的，现在我们使用 GitOps 的方式来改造我们的流水线，将 CD 部分使用 Argo CD 来完成。

![gitops workflow](https://picdn.youdianzhishi.com/images/20210706185635.png)

这里我们要先去回顾下前面的 [Tekton 实战部分的内容](../../tekton/action/)，整个流水线包括 clone、test、build、docker、deploy、rollback 几个部分的任务，最后的 deploy 和 rollback 属于 CD 部分，我们只需要这部分使用 Argo CD 来构建即可。

首先我们将项目 `http://git.k8s.local/course/devops-demo.git` 仓库中的 Helm Chart 模板单独提取出来放到一个独立的仓库中 `http://git.k8s.local/course/devops-demo-deploy`，这样方便和 Argo CD 进行对接，整个项目下面只有用于应用部署的 Helm Chart 模板。

![devops demo deploy repo](https://picdn.youdianzhishi.com/images/1660380317725.png)

如果有多个团队，每个团队都要维护大量的应用，就需要用到 Argo CD 的另一个概念：项目（Project）。Argo CD 中的项目（Project）可以用来对 Application 进行分组，不同的团队使用不同的项目，这样就实现了多租户环境。项目还支持更细粒度的访问权限控制：

  * 限制部署内容（受信任的 Git 仓库）；
  * 限制目标部署环境（目标集群和 namespace）；
  * 限制部署的资源类型（例如 RBAC、CRD、DaemonSets、NetworkPolicy 等）；
  * 定义项目角色，为 Application 提供 RBAC（例如 OIDC group 或者 JWT 令牌绑定）。



比如我们这里创建一个名为 `demo` 的项目，将该应用创建到该项目下，只需创建一个如下所示的 `AppProject` 对象即可：
    
    
    apiVersion: argoproj.io/v1alpha1
    kind: AppProject
    metadata:
      # 项目名
      name: demo
      namespace: argocd
    spec:
      # 目标
      destinations:
        # 此项目的服务允许部署的 namespace，这里为全部
        - namespace: "*"
          # 此项目允许部署的集群，这里为默认集群，即为Argo CD部署的当前集群
          server: https://kubernetes.default.svc
      # 允许的数据源
      sourceRepos:
        - http://git.k8s.local/course/devops-demo-deploy.git
    

该对象中有几个核心的属性：

  * `sourceRepos`：项目中的应用程序可以从中获取清单的仓库引用
  * `destinations`：项目中的应用可以部署到的集群和命名空间
  * `roles`：项目内资源访问定义的角色



直接创建该对象即可：
    
    
    $ kubectl get AppProject -n argocd
    NAME      AGE
    default   79m
    demo      24s
    

然后前往 Argo CD 添加仓库：

![connect repo](https://picdn.youdianzhishi.com/images/1660381892625.jpg)

需要注意的是这里的密码需要使用 AccessToken，我们可以前往 GitLab 的页面 <http://git.k8s.local/-/profile/personal_access_tokens> 创建。

![gitlab token](https://picdn.youdianzhishi.com/images/1660382852725.jpg)

更多配置信息可以前往文档 <https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/> 查看，项目创建完成后，在该项目下创建一个 Application，代表环境中部署的应用程序实例。
    
    
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: devops-demo
      namespace: argocd
    spec:
      destination:
        namespace: default
        server: "https://kubernetes.default.svc"
      project: demo
      source:
        path: helm # 从 Helm 存储库创建应用程序时，chart 必须指定 path
        repoURL: "http://git.k8s.local/course/devops-demo-deploy.git"
        targetRevision: HEAD
        helm:
          parameters:
            - name: replicaCount
              value: "2"
          valueFiles:
            - my-values.yaml
    

这里我们定义了一个名为 `devops-demo` 的应用，应用源来自于 helm 路径，使用的是 `my-values.yaml` 文件，此外还可以通过 `source.helm.parameters` 来配置参数，同步策略我们仍然选择使用手动的方式，我们可以在 Tekton 的任务中去手动触发同步。上面的资源对象创建完成后应用就会处于 `OutOfSync` 状态，因为集群中还没部署该应用。

![new app](https://picdn.youdianzhishi.com/images/1660382968367.jpg)

现在接下来我们去修改之前的 Tekton 流水线，之前的 Pipeline 流水线如下所示：
    
    
    # pipeline.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Pipeline
    metadata:
      name: pipeline
    spec:
      workspaces: # 声明 workspaces
        - name: go-repo-pvc
      params:
        # 定义代码仓库
        - name: git_url
        - name: revision
          type: string
          default: "main"
        # 定义镜像参数
        - name: image
        - name: registry_url
          type: string
          default: "harbor.k8s.local"
        - name: registry_mirror
          type: string
          default: "https://dockerproxy.com"
        # 定义 helm charts 参数
        - name: charts_dir
        - name: release_name
        - name: release_namespace
          default: "default"
        - name: overwrite_values
          default: ""
        - name: values_file
          default: "values.yaml"
      tasks: # 添加task到流水线中
        - name: clone
          taskRef:
            name: git-clone
          workspaces:
            - name: output
              workspace: go-repo-pvc
          params:
            - name: url
              value: $(params.git_url)
            - name: revision
              value: $(params.revision)
        - name: test
          taskRef:
            name: test
          runAfter:
            - clone
        - name: build # 编译二进制程序
          taskRef:
            name: build
          runAfter: # 测试任务执行之后才执行 build task
            - test
            - clone
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
        - name: docker # 构建并推送 Docker 镜像
          taskRef:
            name: docker
          runAfter:
            - build
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
          params: # 传递参数
            - name: image
              value: $(params.image)
            - name: registry_url
              value: $(params.registry_url)
            - name: registry_mirror
              value: $(params.registry_mirror)
        - name: deploy # 部署应用
          taskRef:
            name: deploy
          runAfter:
            - docker
          workspaces:
            - name: source
              workspace: go-repo-pvc
          params:
            - name: charts_dir
              value: $(params.charts_dir)
            - name: release_name
              value: $(params.release_name)
            - name: release_namespace
              value: $(params.release_namespace)
            - name: overwrite_values
              value: $(params.overwrite_values)
            - name: values_file
              value: $(params.values_file)
        - name: rollback # 回滚
          taskRef:
            name: rollback
          when:
            - input: "$(tasks.deploy.results.helm-status)"
              operator: in
              values: ["failed"]
          params:
            - name: release_name
              value: $(params.release_name)
            - name: release_namespace
              value: $(params.release_namespace)
    

现在我们需要去掉最后的 deploy 和 rollback 两个任务，当 Docker 镜像构建推送完成后，我们只需要去修改部署代码仓库中的 values 文件，然后再去手动触发 ArgoCD 同步状态即可（如果开启了自动同步这一步都可以省略了），而回滚操作也是通过操作 Git 仓库来实现的，不需要定义一个单独的 Task 任务。

定义一个如下所的 Taks 任务：
    
    
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: sync
    spec:
      volumes:
        - name: argocd-secret
          secret:
            secretName: $(inputs.params.argocd_secret)
      params:
        - name: argocd_url
          description: "The URL of the ArgoCD server"
        - name: argocd_secret
          description: "The secret containing the username and password for the tekton task to connect to argo"
        - name: app_name
          description: "The name of the argo app to update"
        - name: app_revision
          default: "HEAD"
          description: "The revision of the argo app to update"
      steps:
        - name: deploy
          image: argoproj/argocd:v2.4.9
          volumeMounts:
            - name: argocd-secret
              mountPath: /var/secret
          command:
            - sh
          args:
            - -ce
            - |
              set -e
              echo "starting argocd sync app"
              argocd login --insecure $(params.argocd_url) --username $(/bin/cat /var/secret/username) --password $(/bin/cat /var/secret/password)
              argocd app sync $(params.app_name) --revision $(params.app_revision)
              argocd app wait $(params.app_name) --health
    

由于我们这里只需要修改 Helm Chart 的 Values 文件中的 `image.tag` 参数，最好的方式当然还是在一个 Task 中去修改 `values.yaml` 文件并 commit 到 Repo 仓库中去，当然也可以为了简单直接在 ArgoCD 的应用侧配置参数即可，比如可以使用 `argocd app set` 命令来为应用配置参数，然后下面再用 `argocd app sync` 命令手动触发同步操作，这里其实就可以有很多操作了，比如我们可以根据某些条件来判断是否需要部署，满足条件后再执行 sync 操作，最后使用 `wait` 命令等待应用部署完成。

当然除了通过手动 `argocd app set` 的方式来配置参数之外，可能更好的方式还是直接去修改 Repo 仓库中的 values 值，这样在源代码仓库中有一个版本记录，我们可以新建如下所示的一个任务用来修改 values 值：
    
    
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: change-manifests
    spec:
      params:
        - name: git_url
          description: Git repository containing manifest files to update
        - name: git_email
          default: pipeline@k8s.local
        - name: git_name
          default: Tekton Pipeline
        - name: git_manifest_dir
          description: Manifests files dir
        - name: tool_image
          default: cnych/helm-kubectl-curl-git-jq-yq
        - name: image_tag
          description: Deploy docker image tag
      steps:
        - name: git-push
          image: $(params.tool_image)
          env:
            - name: GIT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: gitlab-auth
                  key: username
                  optional: true
            - name: GIT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: gitlab-auth
                  key: password
                  optional: true
          command: ["/bin/bash"]
          args:
            - -c
            - |
              set -eu
              git config --global user.email "$(params.git_email)"
              git config --global user.name "$(params.git_name)"
              git clone --branch main --depth 1 http://${GIT_USERNAME}:${GIT_PASSWORD}@$(params.git_url) repo
              cd "repo/$(params.git_manifest_dir)"
              ls -l
              echo old value:
              cat my-values.yaml | yq r - 'image.tag'
              echo replacing with new value:
              echo $(params.image_tag)
              yq w --inplace my-values.yaml 'image.tag' "$(params.image_tag)"
              echo verifying new value
              yq r my-values.yaml 'image.tag'
              if ! git diff-index --quiet HEAD --; then
                git status
                git add .
                git commit -m "helm values updated by tekton pipeline in change-manifests task"
                git push
              else
                  echo "no changes, git repository is up to date"
              fi
    

现在我们的流水线就变成了如下所示的清单：
    
    
    # pipeline.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Pipeline
    metadata:
      name: pipeline
    spec:
      workspaces: # 声明 workspaces
        - name: go-repo-pvc
      params:
        # 定义代码仓库
        - name: git_url
        - name: git_infra_url
        - name: revision
          type: string
          default: "main"
        # 定义镜像参数
        - name: image
        - name: image_tag
        - name: registry_url
          type: string
          default: "harbor.k8s.local"
        - name: registry_mirror
          type: string
          default: "https://ot2k4d59.mirror.aliyuncs.com/"
        - name: git_manifest_dir
          default: "helm"
        # 定义 argocd 参数
        - name: argocd_url
        - name: argocd_secret
        - name: app_name
        - name: app_revision
          type: string
          default: "HEAD"
      tasks: # 添加task到流水线中
        - name: clone
          taskRef:
            name: git-clone
          workspaces:
            - name: output
              workspace: go-repo-pvc
          params:
            - name: url
              value: $(params.git_url)
            - name: revision
              value: $(params.revision)
        - name: test
          taskRef:
            name: test
          runAfter:
            - clone
        - name: build # 编译二进制程序
          taskRef:
            name: build
          runAfter: # 测试任务执行之后才执行 build task
            - test
            - clone
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
        - name: docker # 构建并推送 Docker 镜像
          taskRef:
            name: docker
          runAfter:
            - build
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
          params: # 传递参数
            - name: image
              value: $(params.image):$(params.image_tag)
            - name: registry_url
              value: $(params.registry_url)
            - name: registry_mirror
              value: $(params.registry_mirror)
        - name: manifests
          taskRef:
            name: change-manifests
          runAfter:
            - docker
          params:
            - name: git_url
              value: $(params.git_infra_url)
            - name: git_manifest_dir
              value: $(params.git_manifest_dir)
            - name: image_tag
              value: $(params.image_tag)
        - name: sync
          taskRef:
            name: sync
          runAfter:
            - manifests
          params:
            - name: argocd_url
              value: $(params.argocd_url)
            - name: argocd_secret
              value: $(params.argocd_secret)
            - name: app_name
              value: $(params.app_name)
            - name: app_revision
              value: $(params.app_revision)
    

最后创建用于 ArgoCD 登录使用的 Secret 对象：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-auth
    type: Opaque
    stringData:
      username: admin
      password: admin321 # argocd 的密码
    

最后修改 Tekton Triggers 中的 Template，如下所示：
    
    
    # gitlab-template.yaml
    apiVersion: triggers.tekton.dev/v1alpha1
    kind: TriggerTemplate
    metadata:
      name: gitlab-template
    spec:
      params: # 定义参数，和 TriggerBinding 中的保持一致
        - name: gitrevision
        - name: gitrepositoryurl
      resourcetemplates: # 定义资源模板
        - apiVersion: tekton.dev/v1beta1
          kind: PipelineRun # 定义 pipeline 模板
          metadata:
            generateName: gitlab-run- # TaskRun 名称前缀
          spec:
            serviceAccountName: tekton-build-sa
            pipelineRef:
              name: pipeline
            workspaces:
              - name: go-repo-pvc
                persistentVolumeClaim:
                  claimName: go-repo-pvc
            params:
              - name: git_url
                value: $(tt.params.gitrepositoryurl)
              - name: git_infra_url
                value: git.k8s.local/course/devops-demo-deploy.git
              - name: image
                value: "harbor.k8s.local/course/devops-demo"
              - name: image_tag
                value: "$(tt.params.gitrevision)"
              - name: argocd_url
                value: argocd.k8s.local
              - name: argocd_secret
                value: argocd-auth
              - name: app_name
                value: devops-demo
    

现在我们的整个流水线就更加精简了。现在我们去应用仓库中修改下源代码并提交就可以触发我们的流水线了。

![sync app](https://picdn.youdianzhishi.com/images/1660641259148.jpg)

同样可以访问下应用来验证结果是否正确：
    
    
    $ curl devops-demo.k8s.local
    {"msg":"Hello Tekton On GitLab With ArgoCD (GitOps)"}
    

现在查看 Argo CD 中的应用可以发现都是已同步状态了。

![argo app](https://picdn.youdianzhishi.com/images/1660641398369.jpg)

如果需要回滚，则可以直接在 Argo CD 页面上点击 `HISTORY AND ROLLBACK` 安装查看部署的历史记录选择回滚的版本即可：

![history and rollback](https://picdn.youdianzhishi.com/images/20210706185944.png)

可以查看整个 Tekton 流水线的状态：
    
    
    $ tkn pr describe gitlab-run-4npk7
    
    Name:              gitlab-run-4npk7
    Namespace:         default
    Pipeline Ref:      pipeline
    Service Account:   tekton-build-sa
    Timeout:           1h0m0s
    Labels:
     tekton.dev/pipeline=pipeline
     triggers.tekton.dev/eventlistener=gitlab-listener
     triggers.tekton.dev/trigger=gitlab-push-events-trigger
     triggers.tekton.dev/triggers-eventid=6e21e686-79dc-421c-951a-e1591dcfd2f8
    
    🌡️  Status
    
    STARTED          DURATION   STATUS
    10 minutes ago   4m11s      Succeeded
    
    ⚓ Params
    
     NAME              VALUE
     ∙ git_url         http://git.k8s.local/course/devops-demo.git
     ∙ git_infra_url   git.k8s.local/course/devops-demo-deploy.git
     ∙ image           harbor.k8s.local/course/devops-demo
     ∙ image_tag       1a49370f2708a01e8eef14c25688c5e0acf3a07c
     ∙ argocd_url      grpc.argocd.k8s.local
     ∙ argocd_secret   argocd-auth
     ∙ app_name        devops-demo
    
    📂 Workspaces
    
     NAME            SUB PATH   WORKSPACE BINDING
     ∙ go-repo-pvc   ---        PersistentVolumeClaim (claimName=go-repo-pvc)
    
    🗂  Taskruns
    
     NAME                           TASK NAME   STARTED          DURATION   STATUS
     ∙ gitlab-run-4npk7-sync        sync        6 minutes ago    26s        Succeeded
     ∙ gitlab-run-4npk7-manifests   manifests   7 minutes ago    19s        Succeeded
     ∙ gitlab-run-4npk7-docker      docker      10 minutes ago   3m6s       Succeeded
     ∙ gitlab-run-4npk7-build       build       10 minutes ago   10s        Succeeded
     ∙ gitlab-run-4npk7-test        test        10 minutes ago   3s         Succeeded
     ∙ gitlab-run-4npk7-clone       clone       10 minutes ago   7s         Succeeded
    

最后用一张图来总结下我们使用 Tekton 结合 Argo CD 来实现 GitOps 的工作流：

![tekton+argocd](https://picdn.youdianzhishi.com/images/tekton-argocd-workflow.png)

## webhook 配置

我们知道 Argo CD 会自动检查到配置的应用变化，这是因为 Argo CD 会每个三分钟去轮询一次 Git 存储库来检测清单的变化，为了消除这种轮询延迟，我们也可以将 API 服务端配置为接收 webhook 事件的方式，这样就能实时获取到 Git 存储库中的变化了。Argo CD 支持来着 GitHub、GitLab、Bitbucket、Bitbucket Server 和 Gogs 的 Git webhook 事件，这里我们仍然以上面的 GitLab 为例来说明如果配置 Webhook。

进入到 GitLab 项目仓库 <http://git.k8s.local/course/devops-demo-deploy> 中配置 Webhooks：

![配置 Webhooks](https://picdn.youdianzhishi.com/images/20210708150748.png)

Webhook 的地址填写 Argo CD 的 API 接口地址 <http://argocd.k8s.local/api/webhook>，下面的 Secret token 是可选的，建议添加上，任意定义即可。另外需要注意这里我们使用的是自签名的 https 证书，所以需要在下方去掉`启用SSL验证`。

然后需要将上面配置的 Secret token 添加到 Argo CD 的 Secret 配置中：
    
    
    $ kubectl edit secret argocd-secret -n argocd
    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-secret
      namespace: argocd
    type: Opaque
    data:
    ...
    stringData:
      # gitlab webhook secret
      webhook.gitlab.secret: youdianzhishi
    

保存后，更改会自动生效，我们可以在 GitLab 这边测试配置的 Webhook，查看 Argo CD 的 API 服务 Pod 日志，正常就可以收到 Push 事件了：
    
    
    ➜  ~ kubectl logs -f argocd-server-76b578f79f-5zfsg -n argocd
    time="2022-08-16T09:27:12Z" level=info msg="Received push event repo: http://git.k8s.local/course/devops-demo-deploy, revision: main, touchedHead: true"
    time="2022-08-16T09:27:12Z" level=info msg="Requested app 'devops-demo' refresh"
    

## Metrics 指标

Argo CD 作为我们持续部署的关键组件，对于本身的监控也是非常有必要的，Argo CD 本身暴露了两组 Prometheus 指标，所以我们可以很方便对接监控报警。

默认情况下 Metrics 指标通过端点 `argocd-metrics:8082/metrics` 获取指标，包括：

  * 应用健康状态指标
  * 应用同步状态指标
  * 应用同步历史记录



关于 Argo CD 的 API 服务的 API 请求和响应相关的指标（请求数、响应码值等等...）通过端点 `argocd-server-metrics:8083/metrics` 获取。

然后可以根据我们自己的需求来配置指标抓取任务，比如我们是手动维护 Prometheus 的方式，并且开启了 endpoints 这种类型的服务自动发现，那么我们可以在几个指标的 Service 上添加 `prometheus.io/scrape: "true"` 这样的 annotation：
    
    
    $ kubectl edit svc argocd-metrics -n argocd
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/scrape: "true"
      labels:
        app.kubernetes.io/component: metrics
        app.kubernetes.io/name: argocd-metrics
        app.kubernetes.io/part-of: argocd
    ......
    $ kubectl edit svc argocd-server-metrics -n argocd
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8083"  # 指定8083端口为指标端口
      creationTimestamp: "2021-07-03T06:16:47Z"
      labels:
        app.kubernetes.io/component: server
        app.kubernetes.io/name: argocd-server-metrics
        app.kubernetes.io/part-of: argocd
    ......
    $ kubectl edit svc argocd-repo-server -n argocd
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8084"  # 指定8084端口为指标端口
      creationTimestamp: "2021-07-03T06:16:47Z"
      labels:
        app.kubernetes.io/component: repo-server
        app.kubernetes.io/name: argocd-repo-server
        app.kubernetes.io/part-of: argocd
    ......
    

配置完成后正常就可以自动发现上面的几个指标任务了：

![argocd metrics](https://picdn.youdianzhishi.com/images/1660643569746.png)

如果你使用的是 Prometheus Operator 方式，则可以手动创建 ServiceMonitor 对象来创建指标对象。

然后我们可以在 Grafana 中导入 Argo CD 的 Dashboard，地址：<https://github.com/argoproj/argo-cd/blob/master/examples/dashboard.json>

![argocd grafana](https://picdn.youdianzhishi.com/images/1660645025837.jpg)

## 安全

GitOps 的核心理念就是**一切皆代码** ，意味着用户名、密码、证书、token 等敏感信息也要存储到 Git 仓库中，这显然是非常不安全的，不过我们可以通过 Vault、Keycloak、SOPS 等 Secret 管理工具来解决，最简单的方式是使用 SOPS，因为它使用 PGP 密钥来加密内容，如果你使用 kustomize 则还可以在集群内使用相同的 PGP 密钥解密 Secret。ArgoCD 虽然没有内置的 Secret 管理，但是却可以与任何 Secret 管理工具集成。

`sops` 是一款开源的加密文件的编辑器，支持 YAML、JSON、ENV、INI 和 BINARY 格式，同时可以用 AWS KMS、GCP KMS、Azure Key Vault、age 和 PGP 进行加密，官方推荐使用 `age` 来进行加解密，所以我们这里使用 `age`。[age](https://github.com/FiloSottile/age/) 是一个简单、现代且安全的加密工具（和 Go 库）。

### SOPS 与 AGE

首先需要安装 `age` 工具，可以直接从 [Release 页面](https://github.com/FiloSottile/age/releases) 下载对应的安装包：
    
    
    $ wget https://github.91chi.fun/https://github.com//FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz
    $ tar -xvf age-v1.0.0-linux-amd64.tar.gz
    $ mv age/age /usr/local/bin
    $ mv age/age-keygen /usr/local/bin
    $ age --version
    v1.0.0
    

然后安装 sops，同样直接从 [Release 页面](https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64)下载对应的安装包：
    
    
    $ wget https://github.91chi.fun/https://github.com//mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64
    $ mv sops-v3.7.3.linux.amd64 sops && chmod +x sops
    $ mv sops /usr/local/bin
    

通过下述命令来查看安装是否成功：
    
    
    $ sops --version
    sops 3.7.3 (latest)
    

我们先创建一个简单的 Secret 来测试下使用 sops 进行加密：
    
    
    $ kubectl create secret generic app-secret \
    --from-literal=token=SOPS-AGE-TOKEN-TEST \
    --dry-run=client \
    -o yaml > secret.yaml
    

生成的 secret 资源清单文件如下所示：
    
    
    apiVersion: v1
    data:
      token: U09QUy1BR0UtVE9LRU4tVEVTVA==
    kind: Secret
    metadata:
      name: app-secret
    

接下来我们使用 `age-keygen` 命令生成加密的公钥和私钥，可以用如下命令将私钥保存到一个 `key.txt` 文件中：
    
    
    $ age-keygen -o key.txt
    Public key: age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt
    

然后我们可以使用上面的私钥来加密生成的 `secret.yaml` 文件：
    
    
    $ age -o secret.enc.yaml -r age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt secret.yaml
    

加密后生成的 `secret.enc.yaml` 文件内容如下所示，显示乱码：
    
    
    age-encryption.org/v1
    -> X25519 x8bynJlv6Sz03ks71Jvn92RZQ6IlTj9B8zgU3lJsOFQ
    sqrP+zq9nw93mafbBjuc5F6GWIjjzdYtQV6DtV9KiTw
    ---
    6W1cpc//EBqXkF983yVBUBExiYEx/7Y0wEvHjPlmWNg
    ��NY0Y���^�/A��i��.�N���=�ԦPb�ļ���҈v?-<t�t�
    Ӓ/$�Zs�۸�gKz�U���Kf�aϛ��        �+
    ��Y��j��g��IDP>��>g��2m9R�a��qfC�����߻q�n���@�O�'g�P6
    

同样我们还可以对该加密文件进行解密：
    
    
    $ age --decrypt -i key.txt secret.enc.yaml
    apiVersion: v1
    data:
      token: U09QUy1BR0UtVE9LRU4tVEVTVA==
    kind: Secret
    metadata:
      creationTimestamp: null
      name: app-secret
    

同样对于 `sops` 来说也是支持和 `age` 进行集成的，我们可以使用下面的 `sops` 命令来对 `secret.yaml` 文件进行加密：
    
    
    $ sops --encrypt --age age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt secret.yaml > secret.enc.yaml
    

加密后的文件内容如下所示：
    
    
    apiVersion: ENC[AES256_GCM,data:e7E=,iv:Pfwj3/74CygAHtWlt9tsnexrH74nfa0teNZzknzfGwA=,tag:U2yJjnalFOuGe8rQK+c7Ng==,type:str]
    data:
      token: ENC[AES256_GCM,data:8kwq4GqETBJjHbrtS5S3AqJIPcq3Nmf8Gg1muQ==,iv:l7O1UnjzcXOkc48EVvbqGPVv0RQxxNX3aIzCU5B/7/o=,tag:XuNw/N7XDLU17BOQkjn5Rg==,type:str]
    kind: ENC[AES256_GCM,data:U4hGrF9C,iv:CloG5/RgWHXN/lNGKHGNxeZJXj8kfjw8OmFAxQblUgY=,tag:gq0wKDUa50odvRNcak+Vig==,type:str]
    metadata:
      creationTimestamp: null
      name: ENC[AES256_GCM,data:PEhXQdE3/vj+bA==,iv:dkWCj5cAqc4IeB2lXdxC7otmCmFn3vGe5s2Ij3uh8ag=,tag:bbUaA1dqXnrLaTnCPVnxpQ==,type:str]
    sops:
      kms: []
      gcp_kms: []
      azure_kv: []
      hc_vault: []
      age:
        - recipient: age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBwY3JKdmxVM2lFb0NpTjVj
            cGdyc3d1QXBvN3RVdzAwMVNVMXZrS3pLYm1zCnZqTGZ5TzVBL2VSay80RkFFTlBC
            R1NtZmxoYVlTd2RyWUl1c24wME83K00KLS0tIENlczRGb1QzRCtCeWxpMU9PTXN5
            QnpyckI1bmZSSFliMUgyUDlkd0tWalUKK4vKJwcGLsZn5wT9WHh5tvNOEGScOlAb
            Fx118rutRK4nVpfIhAvhfS9TDqvhaQ2wFVv3N/a/BhkYpwTrE/cjmQ==
            -----END AGE ENCRYPTED FILE-----
      lastmodified: "2022-08-18T08:04:35Z"
      mac: ENC[AES256_GCM,data:/ujRqRKFR/5uqRBGAZzVIsdVR95In18zUrKuHFuJnHrrfRAt4WXzSUTBovIqOaGPQxXvY4jqkWnd7kqlO629CjK3SA6selEb8N6ytN5kGquGUqSYlOAjsnk575VtpMKXIr8jeaGkzJRmU6aEnbPa18kekw0FCX1aP6yubD8Ce2Y=,iv:/bRn1tk7iXplz4OGxqkUGD4UQRRtb5jUnICQyFnT4fg=,tag:kt9CzFye1OXsq+MKXTZeXA==,type:str]
      pgp:
        - created_at: "2022-08-18T08:04:35Z"
          enc: |-
            -----BEGIN PGP MESSAGE-----
    
            wcFMA0Eva10jiAHJAQ/+LgUsrJKoo95yCIxbMT1OPjnJhAK/LkIwY9EdHbJewphI
            CKwpDwvsrbdpjcmBkCt4sL4S30bPR3qdAjLxJCnGTJPZQzxjOEIzvJNAG5nC3zk/
            UVPAWj7nV26CCPMc+/j/GHGwMphoLviMr9et0adtaWILSP0yhMuH8LVzGa04WVEz
            AihT849sF/+WrUy4f7axI4Z2IH2mEepSqNZDQR9mmiu+nA9e+QZqsfazLJXRPsNd
            2hQn7qSGPZ10bzy9ccA5nO5r1oU2J+GEEMYujur/RL8y5oi3BCSvWc0udfuU0dka
            Nn77OA73zS8aziA9pj3D46wgeGYFfX7h2XKytSI15GGTAT7RmM6D2cB9xWzeQncy
            4TN0LDvcw/7SRjxY55iDyYHPLTNlMfajKwXoKfeQX5nd0rnZRCovYDoj2OrqZDff
            1N25EEWN6MSztZML0eE/k/p7RDBG9bJ6lntXNAXQJRjzhUYeHMnXLc9NCN5P3WdW
            Ny155SsGK6n9Ok1SdAolqlOFRKiO8AA+2jPVS7aDUrWktqPCa8hzf/Bm1ttBoYjw
            D5Xc5x3IcyZDIISqz/9cQYfiPusZohpGnfwoea5qhvXEY/wM5IwfLdTm8u78djho
            HMLFdFUzuprkHZlZlP3HfPbZi5wGpmiqAuYX+i40teOEaQNGhE7HKCJZkAVS0J3S
            UQHmBMxL1SL/JGAdSsuddB0liIIriENIxr14W04zeJ+pClxvnzxNYigOYM3Jk8wF
            w7zmhD3IvEpSLG0f4a/c486LpNryBBz6qzBZRYqnJ87PQQ==
            =K5dC
            -----END PGP MESSAGE-----
          fp: CCC4D0692165A88405EF1F579CC5737D5CCB9760
      unencrypted_suffix: _unencrypted
      version: 3.7.3
    

可以看到主要字段都被加密了。但是其他字段比如 kind 也被加密了，我们可以通过创建一个 `.sops.yaml` 文件来指定需要被加密的字段，如下所示：
    
    
    # .sops.yaml
    creation_rules:
      - encrypted_regex: "^(username|password|)$"
        age: "CCC4D0692165A88405EF1F579CC5737D5CCB9760"
    

这样的话则只会对 `username` 和 `password` 两个字段进行加密。

### ArgoCD 集成 SOPS

现在我们可以使用 `sops` 来对私密的文件进行加解密了，前面示例中我们在 ArgoCD 中使用的 Helm Chart 方式来同步应用，比如我们会在 values 文件中提供一些比较私密的信息，直接明文提供存储到 Git 仓库上显然是非常不安全的，这个时候我们就可以使用 `sops` 来对这些 values 文件进行加密，当然在同步应用的时候自然就需要 ArgoCD 能够支持对手 `SOPS` 进行解密了，这里我们还需要使用到 [helm-secrets](https://github.com/jkroepke/helm-secrets) 这个 Helm 插件。

接下来我们需要让 Argo CD 来支持 SOPS，一般来说主要有两种方法：

  * 使用 helm 和 sops 创建自定义的 ArgoCD Docker 镜像，并使用自定义 Docker 镜像，但是 Argo CD 的每个新版本都需要更新该镜像。
  * 在 Argo CD 存储库服务器部署中添加一个初始化容器，以获取带有 `sops` 的 helm 插件，如此处所述，并在 Pod 中使用它。即使更新了 Argo CD 版本，也不需要更新插件，除非插件版本和 Argo CD 版本存在兼容性问题。



为了简单我们这里使用第一种自定义镜像的方式，如下所示的 Dockerfile，它将 `sops` 和 `helm-secrets` 集成到 Argo CD 镜像中：
    
    
    ARG ARGOCD_VERSION="v2.4.9"
    FROM argoproj/argocd:$ARGOCD_VERSION
    ARG SOPS_VERSION="3.7.3"
    ARG VALS_VERSION="0.18.0"
    ARG HELM_SECRETS_VERSION="3.15.0"
    ARG KUBECTL_VERSION="1.24.3"
    # In case wrapper scripts are used, HELM_SECRETS_HELM_PATH needs to be the path of the real helm binary
    ENV HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
        HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/" \
        HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
        HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false \
        HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false
    
    USER root
    RUN apt-get update && \
        apt-get install -y \
          curl && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
    RUN curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
        -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
    
    # sops backend installation
    RUN curl -fsSL https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux \
        -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops
    
    # vals backend installation
    RUN curl -fsSL https://github.com/variantdev/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz \
        | tar xzf - -C /usr/local/bin/ vals \
        && chmod +x /usr/local/bin/vals
    
    USER 999
    
    RUN helm plugin install --version ${HELM_SECRETS_VERSION} https://github.com/jkroepke/helm-secrets
    

使用上面的 Dockerfile 重新构建镜像（cnych/argocd:v2.4.9）后，重新替换 `argocd-repo-server` 应用的镜像，其他组件不需要。

由于默认情况下 ArgoCD 只支持 `http://` 和 `https://` 作为远程 value 协议，所以我们需要讲 `helm-secrets` 协议也添加到 `argocd-cm` 这个 ConfigMap 中去。
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      labels:
        app.kubernetes.io/name: argocd-cm
        app.kubernetes.io/part-of: argocd
      name: argocd-cm
    data:
      helm.valuesFileSchemes: >-
        secrets+gpg-import, secrets+gpg-import-kubernetes,
        secrets+age-import, secrets+age-import-kubernetes,
        secrets,
        https
    

接下来我们还需要配置 Argo CD 存储库服务器，使它可以访问私钥来解密加密的文件。这里使用前面 `age-keygen` 命令生成的私钥文件 `key.txt` 创建一个 Kubernetes Secret 对象：
    
    
    $ kubectl create secret generic helm-secrets-private-keys --from-file=key.txt -n argocd
    

现在我们需要将该 Secret 以 Volume 的形式挂载到 `argocd-repo-server` 中去:
    
    
    volumes:
      - name: helm-secrets-private-keys
        secret:
          secretName: helm-secrets-private-keys
    # ......
      volumeMounts:
        - mountPath: /helm-secrets-private-keys/
          name: helm-secrets-private-keys
    ......
    

然后更新 `argocd-repo-server` 组件，更新完成后我们就可以创建如下所示的 Argo CD 应用来对加密文件进行解密了：
    
    
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: app
    spec:
      source:
        helm:
          valueFiles:
            # Method 1: Mount the gpg key from a kubernetes secret as volume
            # secrets+gpg-import://<key-volume-mount>/<key-name>.asc?<relative/path/to/the/encrypted/secrets.yaml>
            # secrets+age-import://<key-volume-mount>/<key-name>.txt?<relative/path/to/the/encrypted/secrets.yaml>
            # Example Method 1: (Assumptions: key-volume-mount=/helm-secrets-private-keys, key-name=app, secret.yaml is in the root folder)
            - secrets+age-import:///helm-secrets-private-keys/key.txt?secrets.yaml
    

现在我们再次使用前面的 `devops-demo` 应用示例进行测试。

![devops-demo deploy](https://picdn.youdianzhishi.com/images/1660804972187.png)

我们使用 `sops` 将要部署的 `my-values.yaml` 文件进行加密：
    
    
    $ sops --encrypt --age age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt my-values.yaml > my-values.enc.yaml
    

加密后的文件内容如下所示：
    
    
    image:
      repository: ENC[AES256_GCM,data:ZDnA7yTAe2B+TbcQYhcs4yufLgXJWHzX7IUnYdOXtsqzfEo=,iv:4yn+RkQoTHNVW8Y5yDzHsY2hhpMo8yw6j/uj9g6AvMA=,tag:IPwFo2AfLT7yBwoKrvCLCg==,type:str]
      tag: ENC[AES256_GCM,data:koDRtD5NfWn03JJLAZnYYWLgwsJr/kSKtw8WHJoeSLD8Zco4M0Doqw==,iv:DbxefZ03J7dGRviRq2DQHhRkcBiBY5FgSh1lJwjwzEg=,tag:zc6ZL5ObSymSVH+caxUzpA==,type:str]
      pullPolicy: ENC[AES256_GCM,data:dJ+xl6llTN2NcEKL,iv:XhX3RGirpJI0Wc1Q/9ld2xWQYqE+6ZLL6laIXEI1unQ=,tag:dDwEUa7nTq9TOkYI2cE0Pg==,type:str]
    ingress:
      enabled: ENC[AES256_GCM,data:eZB9GA==,iv:p12fWs14ATWke0IiMz0SpAb2rW+ViYcEpGRbOoNt9Uk=,tag:w371uI/KRESNP30eD9rrTQ==,type:bool]
      ingressClassName: ENC[AES256_GCM,data:WviAhbo=,iv:Vqx0R8RVWkGipZkR2HZfyOYyZdkc+1fhFEV7AdpI4t0=,tag:fv2hf94svXOQeqfjqXN4gg==,type:str]
      path: ENC[AES256_GCM,data:jg==,iv:cRm/OXlGEbNEHhAAm/JpPx5sP9GRmW1fyEAi+SZhfjY=,tag:QAJmQSQ5qWfjnzrm+MWLbQ==,type:str]
      hosts:
        - ENC[AES256_GCM,data:tb32cnmE1d2qnzzsmG2NzMVOPxkW,iv:RH57dgs0gIS28mB83YX+SQNFNjwoTfPa28YvZsCAJW4=,tag:J7SJXkZKPyydx8NvvCh22w==,type:str]
    resources:
      limits:
        cpu: ENC[AES256_GCM,data:uys2,iv:UfAl2lP2wLzc0GkLcBs33vl4dQqLiXWmoyyucqovuVM=,tag:yXRpMIS11s0iqVZQpJ/Bdw==,type:str]
        memory: ENC[AES256_GCM,data:fBHSfog=,iv:lf6fTZfOPlhQVspm2BAl56ps8Q5W6Qz4tMT7A8Au9tA=,tag:XZqHEWEb2qBjWms/qTsAOQ==,type:str]
      requests:
        cpu: ENC[AES256_GCM,data:MDYW,iv:/j6A3oVQ4HILXFLVAr8Rjcq2CDdHrtPa70uySxQQeBI=,tag:EyWwWl0hFkTWzHFBXndFeA==,type:str]
        memory: ENC[AES256_GCM,data:qiwPiRI=,iv:m/oFxJrcdysf26ry7LEcL6IQRRqi5B8Zsjc/YJOkO7c=,tag:3brvdx+dFUN0VyJ6KO8biQ==,type:str]
    sops:
      kms: []
      gcp_kms: []
      azure_kv: []
      hc_vault: []
      age:
        - recipient: age1wvdahagxfgqc53awmmgz52njdk2zm6vkw760tc368gstsypgvusqy7zvtt
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAyeHNNTWJhWHZHZERJNnlh
            L1FpMkdibERFM2ZtU2FFZ1VhMnYxVG90dUNBCmpTVEk3ODg4aWlhOEY3cDdMSWFW
            ZmdoaGtQT3NDU0E0bEZPQlJqNXNuamsKLS0tIHhEcm5memczQTNaVGZzUGNGQmsw
            cW1QSDd4dDdwZnI2ZzloM2tGRFJxTW8KMPU93lWiNMMaCfOUANmsv+kfi4R7NAzP
            nV2H2EyCTQGsNTeKCS/HkmiSD4/4RLui4Z6TbPf8ALpeGHDH8rVSoA==
            -----END AGE ENCRYPTED FILE-----
      lastmodified: "2022-08-18T08:18:05Z"
      mac: ENC[AES256_GCM,data:Z+KJTZRP6L2QEcSG6S43fvqWsROAwEVnQcVkpN/yU1Kk8x0PUXXZkdyJiykQ+7HRBNWJp1wKF1TAlqnrZyUSXx7zl5fZGbalgK8kRKzzTzdSsB+Cp4Km5uYNqWUh+RFtzRVOYwOU7fOsAxiHLFMjzaqLAE6+WsCY9xjfj67NymA=,iv:Kyckp64XCkmpbeSEiampXp47Qr9ZIJRZUWsLDhHIw/4=,tag:/eH5d5e9anLRoiCxdWPS/w==,type:str]
      pgp:
        - created_at: "2022-08-18T08:18:05Z"
          enc: |-
            -----BEGIN PGP MESSAGE-----
    
            wcFMA0Eva10jiAHJAQ/9HZJck5xCbIB43fYrmnrMokwQB5HPMMCpl8gw/U4Cz/RD
            zs6nlIXhO1U29rQT3s2G9IjfCS0ehfwA6lKGXAuK10jY9HJ7dVthWnKlNsCq35d/
            5ZKzKIT2mvK1h6+qYai86FwGyG436nAw198oNvC4d9E46PfBcx7PXP1lRFoOJI7V
            St81HwFTWOd88tkPyIfv2XW1bcvWo7Qz8YunNqGriD3SREwgkSlcyIL4neumWAru
            YGzTmwEXFjwcTIzel57fI42Qd61wq1p7CKw8njs1pOGucC3uX1b99f1BaeLdQl3C
            lJvYrP0SYKJ/JA2kPRkeJHDd39ywI8A/iNOW4nRFxbMoAHdEiwAUg2DOCfMwDgVu
            WQiQqTF+7AycdqjpXYjYZ7SI3al6jhcDA2KxvNsPNjT8F5yl3c9MIwMdo/NRoc6G
            XNGXqbR+8kChFQiVKCUopbCqHtFaVVV6Ldhk3fB76ht3vgJx9XFR8+KYFLHAezIO
            VdzzWqVPv72lO3CkyqHfoL8FwxjNI9KAQkU1T3ETv5YJw7mUWWvdMVee9SVf8Qa1
            m3JJGqcRd9kyH/u8tMKsrgfG1/KVeyx1gStlO3ioHlCyjsNBAUZ2QIsFa7gxUmQL
            HqgCIqGC/SjFv1+5sHF807sYBBWfARQZRTum/Pg3FHpRiVhNPcvEUPIZjQhT79fS
            UQHw1EvK5Wj4Ea3/3jNt9bim+pJrxCoUAKByU8lyjL7vOsogiM7sgp50t54oI/3V
            G0hvOZNvWV/V0YLqXoTVEru/rqLUKzHunl9psutAXlUOkA==
            =4l27
            -----END PGP MESSAGE-----
          fp: CCC4D0692165A88405EF1F579CC5737D5CCB9760
      unencrypted_suffix: _unencrypted
      version: 3.7.3
    

现在我们需要将该文件重新提交到 Git 仓库中去，接着我们要重新创建 Application 应用，对应的资源清单文件如下所示：
    
    
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: devops-demo
      namespace: argocd
    spec:
      destination:
        namespace: default
        server: "https://kubernetes.default.svc"
      project: demo
      source:
        path: helm # 从 Helm 存储库创建应用程序时，chart 必须指定 path
        repoURL: "http://git.k8s.local/course/devops-demo-deploy.git"
        targetRevision: HEAD
        helm:
          parameters:
            - name: replicaCount
              value: "2"
          valueFiles:
            - secrets+age-import:///helm-secrets-private-keys/key.txt?my-values.enc.yaml
    

其中核心是 `valuesFiles` 配置的 `secrets+age-import:///helm-secrets-private-keys/key.txt?my-values.enc.yaml`，表示导入 `/helm-secrets-private-keys/key.txt` 文件中的私钥来对 `my-values.enc.yaml` 文件进行解密。

重新创建上面的对象后，我们可以同步应用来验证结果是否正确。

![应用同步](https://picdn.youdianzhishi.com/images/1660810844961.png)

## 消息通知

上面我们配置了 Argo CD 的监控指标，我们可以通过 AlertManager 来进行报警，但是有的时候我们可能希望将应用同步的状态发送到指定的渠道，这样方便我们了解部署流水线的结果，Argo CD 本身并没有提供内置的同步状态通知功能，但是我们可以与第三方的系统进行集成。

  * [ArgoCD Notifications](https://github.com/argoproj-labs/argocd-notifications) \- Argo CD 通知系统，持续监控 Argo CD 应用程序，旨在与各种通知服务集成，例如 Slack、SMTP、Telegram、Discord 等（现在已经合并到 Argo CD 主代码库去了），可以直接查看文档 <https://argo-cd.readthedocs.io/en/latest/operator-manual/notifications/>。
  * [Argo Kube Notifier](https://github.com/argoproj-labs/argo-kube-notifier) \- 通用 Kubernetes 资源控制器，允许监控任何 Kubernetes 资源并在满足配置的规则时发送通知。
  * [Kube Watch](https://github.com/bitnami-labs/kubewatch) \- 可以向 Slack/hipchat/mattermost/flock 频道发布通知，它监视集群中的资源变更并通过 webhook 通知它们。



我们知道 Argo CD 本身是提供 resource hook 功能的，在资源同步前、中、后提供脚本来执行相应的动作, 那么想在资源同步后获取应用的状态，然后根据状态进行通知就非常简单了，通知可以是很简单的 curl 命令：

  * PreSync: 在同步之前执行相关操作，这个一般用于比如数据库操作等
  * Sync: 同步时执行相关操作，主要用于复杂应用的编排
  * PostSync: 同步之后且 app 状态为 health 执行相关操作
  * SyncFail: 同步失败后执行相关操作，同步失败一般不常见



但是对于 `PostSync` 可以发送成功的通知，但对于状态为 Processing 的无法判断，而且通知还是没有办法做到谁执行的 pipeline 谁接收通知的原则，没有办法很好地进行更细粒度的配置。`ArgoCD Notifications` 就可以来解决我们的问题，这里我们就以 `ArgoCD Notifications` 为例来说明如何使用钉钉来通知 Argo CD 的同步状态通知。

`ArgoCD Notifications` 默认已经随着 Argo CD 安装了：
    
    
    $ kubectl get pods -n argocd
    NAME                                                READY   STATUS    RESTARTS       AGE
    argocd-notifications-controller-5b56f6f7bb-jqpng    1/1     Running   1 (163m ago)   3d2h
    # ......
    

然后我们需要在钉钉群中创建一个机器人，现在的机器人安全认证有几种方式，这里我们就选择关键字的方式，配置包含 `ArgoCD` 关键字的机器人：

![add dingtalk robot](https://picdn.youdianzhishi.com/images/20210708182637.png)

然后我们需要修改 `install.yaml` 文件中的 `argocd-notifications-cm` 添加相关配置才能支持钉钉。
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: argocd-notifications-cm
    data:
      service.webhook.dingtalk: |
        url: https://oapi.dingtalk.com/robot/send?access_token=31429a8a66c8cd5beb7c4295ce592ac3221c47152085da006dd4556390d4d7e0
        headers:
          - name: Content-Type
            value: application/json
      context: |
        argocdUrl: http://argocd.k8s.local
      template.app-sync-change: |
        webhook:
          dingtalk:
            method: POST
            body: |
              {
                    "msgtype": "markdown",
                    "markdown": {
                        "title":"ArgoCD同步状态",
                        "text": "### ArgoCD同步状态\n> - app名称: {{.app.metadata.name}}\n> - app同步状态: {{ .app.status.operationState.phase}}\n> - 时间:{{.app.status.operationState.startedAt}}\n> - URL: [点击跳转ArgoCD]({{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true) \n"
                    }
                }
      trigger.on-deployed: |
        - description: Application is synced and healthy. Triggered once per commit.
          oncePer: app.status.sync.revision
          send: [app-sync-change]  # template names
          # trigger condition
          when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
      trigger.on-health-degraded: |
        - description: Application has degraded
          send: [app-sync-change]
          when: app.status.health.status == 'Degraded'
      trigger.on-sync-failed: |
        - description: Application syncing has failed
          send: [app-sync-change]  # template names
          when: app.status.operationState.phase in ['Error', 'Failed']
      trigger.on-sync-running: |
        - description: Application is being synced
          send: [app-sync-change]  # template names
          when: app.status.operationState.phase in ['Running']
      trigger.on-sync-status-unknown: |
        - description: Application status is 'Unknown'
          send: [app-sync-change]  # template names
          when: app.status.sync.status == 'Unknown'
      trigger.on-sync-succeeded: |
        - description: Application syncing has succeeded
          send: [app-sync-change]  # template names
          when: app.status.operationState.phase in ['Succeeded']
      subscriptions: |
        - recipients: [dingtalk]  # 可能有bug，正常应该是webhook:dingtalk
          triggers: [on-sync-running, on-deployed, on-sync-failed, on-sync-succeeded]
    

其中 `argocd-notifications-cm` 中添加了一段如下所示的配置：
    
    
    subscriptions: |
      - recipients: [dingtalk]
        triggers: [on-sync-running, on-deployed, on-sync-failed, on-sync-succeeded]
    

这个是为定义的触发器添加通知订阅，正常这里的 `recipients` 是 `webhook:dingtalk`，不知道是否是因为该版本有 bug，需要去掉前缀才能正常使用。

此外还可以添加一些条件判断，如下所示：
    
    
    subscriptions:
      # global subscription for all type of notifications
      - recipients:
          - slack:test1
          - webhook:github
      # subscription for on-sync-status-unknown trigger notifications
      - recipients:
          - slack:test2
          - email:test@gmail.com
        trigger: on-sync-status-unknown
      # global subscription restricted to applications with matching labels only
      - recipients:
          - slack:test3
        selector: test=true
    

然后可以根据不同的状态来配置不同的触发器，如下所示：
    
    
    trigger.on-sync-status-unknown: |
      - description: Application status is 'Unknown'
        send: [app-sync-change]  # template names
        when: app.status.sync.status == 'Unknown'
    

该触发器定义包括名称、条件和通知模板引用:

  * **send** ：表示通知内容使用的模板名称
  * **description** ：当前触发器的描述信息
  * **when** ：条件表达式，如果应发送通知，则返回 true



然后下面就是配置发送的消息通知模板：
    
    
    template.app-sync-change: |
      webhook:
        dingtalk:
          method: POST
          body: |
            {
                  "msgtype": "markdown",
                  "markdown": {
                      "title":"ArgoCD同步状态",
                      "text": "### ArgoCD同步状态\n> - app名称: {{.app.metadata.name}}\n> - app同步状态: {{ .app.status.operationState.phase}}\n> - 时间:{{.app.status.operationState.startedAt}}\n> - URL: [点击跳转ArgoCD]({{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true) \n"
                  }
              }
    

该模板用于生成通知内容，该模板利用 Golang 中的 `html/template` 包定义，允许定义通知标题和正文，可以重用，并且可以由多个触发器引用。每个模板默认都可以访问以下字段：

  * `app`：保存应用程序对象
  * `context`：是用户定义的字符串映射，可能包含任何字符串键和值
  * `notificationType` 保留通知服务类型名称，该字段可用于有条件地呈现服务特定字段



然后记得使用钉钉机器人的 webhook 地址替换掉上面的 `argocd-notifications-secret` 中的 url 地址。

配置完成后直接创建整个资源清单文件：
    
    
    ➜  ~ kubectl apply -f install.yaml
    ➜  ~ kubectl get pods -n argocd
    NAME                                               READY   STATUS    RESTARTS   AGE
    argocd-application-controller-0                    1/1     Running   0          5d4h
    argocd-dex-server-76ff776f97-ds7mm                 1/1     Running   0          5d4h
    argocd-notifications-controller-5c548f8dc9-dx824   1/1     Running   0          9m22s
    argocd-redis-747b678f89-w99wf                      1/1     Running   0          5d4h
    argocd-repo-server-6fc4456c89-586zl                1/1     Running   0          5d4h
    argocd-server-5cc96b75b4-zws2c                     1/1     Running   0          4d22h
    

安装完成后重新去修改下应用代码触发整个 GitOps 流水线，正常就可以在钉钉中收到如下所示的消息通知了，如果没有正常收到消息，可以通过 argocd-notifications 的 CLI 命令进行调试：
    
    
    ➜  ~ kubectl exec -it argocd-notifications-controller-5c548f8dc9-dtq7h -n argocd -- /app/argocd-notifications template notify app-sync-change guestbook --recipient dingtalk
    DEBU[0000] Sending request: POST /robot/send?access_token=31429a8a66c8cd5beb7c4295ce592ac3221c47152085da006dd4556390d4d7e0 HTTP/1.1
    Host: oapi.dingtalk.com
    Content-Type: application/json
    
    {
          "msgtype": "markdown",
          "markdown": {
              "title":"ArgoCD同步状态",
              "text": "### ArgoCD同步状态\n> - app名称: guestbook\n> - app同步状态: Succeeded\n> - 时间:2021-07-03T12:53:44Z\n> - URL: [点击跳转ArgoCD](http://argocd.k8s.local/applications/guestbook?operation=true) \n"
          }
      }  service=dingtalk
    DEBU[0000] Received response: HTTP/2.0 200 OK
    Cache-Control: no-cache
    Content-Type: application/json
    Date: Thu, 08 Jul 2021 11:45:12 GMT
    Server: Tengine
    
    {"errcode":0,"errmsg":"ok"}  service=dingtalk
    

![钉钉通知](https://picdn.youdianzhishi.com/images/20210708195833.png)
