# Jenkins

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/devops/jenkins.md "编辑此页")

# Jenkins

提到基于 Kubernete 的 CI/CD，可以使用的工具有很多，比如 Jenkins、Gitlab CI 以及新兴的 drone 之类的，我们这里会使用大家最为熟悉的 Jenkins 来做 CI/CD 的工具。

## 安装

既然要基于 Kubernetes 来做 CI/CD，我们这里最好还是将 Jenkins 安装到 Kubernetes 集群当中，安装的方式也很多，我们这里仍然还是使用手动的方式，这样可以了解更多细节，对应的资源清单文件如下所示：
    
    
    # jenkins.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: jenkins-pvc
      namespace: kube-ops
    spec:
      storageClassName: local-path # 指定一个可用的 storageclass
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: jenkins
      namespace: kube-ops
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: jenkins
    rules:
      - apiGroups: ["extensions", "apps"]
        resources: ["deployments", "ingresses"]
        verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
      - apiGroups: [""]
        resources: ["services"]
        verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
      - apiGroups: [""]
        resources: ["pods/log", "events"]
        verbs: ["get", "list", "watch"]
      - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["get"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: jenkins
      namespace: kube-ops
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: jenkins
    subjects:
      - kind: ServiceAccount
        name: jenkins
        namespace: kube-ops
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: jenkins
      namespace: kube-ops
    spec:
      selector:
        matchLabels:
          app: jenkins
      template:
        metadata:
          labels:
            app: jenkins
        spec:
          serviceAccount: jenkins
          initContainers:
            - name: fix-permissions
              image: busybox:1.35.0
              command: ["sh", "-c", "chown -R 1000:1000 /var/jenkins_home"]
              securityContext:
                privileged: true
              volumeMounts:
                - name: jenkinshome
                  mountPath: /var/jenkins_home
          containers:
            - name: jenkins
              image: jenkins/jenkins:2.356
              imagePullPolicy: IfNotPresent
              env:
                - name: JAVA_OPTS
                  value: -Dhudson.model.DownloadService.noSignatureCheck=true
              ports:
                - containerPort: 8080
                  name: web
                  protocol: TCP
                - containerPort: 50000
                  name: agent
                  protocol: TCP
              resources:
                limits:
                  cpu: 1500m
                  memory: 2048Mi
                requests:
                  cpu: 1500m
                  memory: 2048Mi
              readinessProbe:
                httpGet:
                  path: /login
                  port: 8080
                initialDelaySeconds: 60
                timeoutSeconds: 5
                failureThreshold: 12
              volumeMounts:
                - name: jenkinshome
                  mountPath: /var/jenkins_home
          volumes:
            - name: jenkinshome
              persistentVolumeClaim:
                claimName: jenkins-pvc
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: jenkins
      namespace: kube-ops
      labels:
        app: jenkins
    spec:
      selector:
        app: jenkins
      ports:
        - name: web
          port: 8080
          targetPort: web
        - name: agent
          port: 50000
          targetPort: agent
    ---
    apiVersion: apisix.apache.org/v2beta2
    kind: ApisixRoute
    metadata:
      name: jenkins
      namespace: kube-ops
    spec:
      http:
        - name: main
          match:
            hosts:
              - jenkins.k8s.local
            paths:
              - "/*"
          backends:
            - serviceName: jenkins
              servicePort: 8080
    # ---
    # apiVersion: extensions/v1beta1
    # kind: Ingress
    # metadata:
    #   name: jenkins
    #   namespace: kube-ops
    # spec:
    #   rules:
    #   - host: jenkins.k8s.local
    #     http:
    #       paths:
    #       - backend:
    #           serviceName: jenkins
    #           servicePort: web
    ---
    # apiVersion: traefik.containo.us/v1alpha1
    # kind: IngressRoute
    # metadata:
    #   name: jenkins
    #   namespace: kube-ops
    # spec:
    #   entryPoints:
    #     - web
    #   routes:
    #     - kind: Rule
    #       match: Host(`jenkins.k8s.local`)
    #       services:
    #         - name: jenkins
    #           port: 8080
    

我们这里使用 `jenkins/jenkins:lts` 镜像，这是 jenkins 官方的 Docker 镜像，然后也有一些环境变量，当然我们也可以根据自己的需求来定制一个镜像，比如我们可以将一些插件打包在自定义的镜像当中，可以参考文档：<https://github.com/jenkinsci/docker>，我们这里使用默认的官方镜像就行，另外一个还需要注意的数据的持久化，将容器的 `/var/jenkins_home` 目录持久化即可，我们这里使用的是一个 StorageClass。

由于我们这里使用的镜像内部运行的用户 `uid=1000`，所以我们这里挂载出来后会出现权限问题，为解决这个问题，我们同样还是用一个简单的 `initContainer` 来修改下我们挂载的数据目录。

另外由于 jenkens 会对 `update-center.json` 做签名校验安全检查，这里我们需要先提前关闭，否则下面更改插件源可能会失败，通过配置环境变量 `JAVA_OPTS=-Dhudson.model.DownloadService.noSignatureCheck=true` 即可。

另外我们这里还需要使用到一个拥有相关权限的 `serviceAccount：jenkins`，我们这里只是给 jenkins 赋予了一些必要的权限，当然如果你对 serviceAccount 的权限不是很熟悉的话，我们给这个 sa 绑定一个 `cluster-admin` 的集群角色权限也是可以的，当然这样具有一定的安全风险。最后就是通过 IngressRoute 来暴露我们的服务，这个比较简单。

我们直接来创建 jenkins 的资源清单即可：
    
    
    $ kubectl apply -f jenkins.yaml
    $ kubectl get pods -n kube-ops -l app=jenkins
    NAME                       READY   STATUS    RESTARTS   AGE
    jenkins-556cd59c8c-2vl8m   1/1     Running   0          44s
    $ kubectl logs -f jenkins-875f5bbb9-jlr46 -n kube-ops
    Running from: /usr/share/jenkins/jenkins.war
    webroot: EnvVars.masterEnvVars.get("JENKINS_HOME")
    ......
    2022-07-02 07:24:05.592+0000 [id=31]    INFO    jenkins.install.SetupWizard#init:
    
    *************************************************************
    *************************************************************
    *************************************************************
    
    Jenkins initial setup is required. An admin user has been created and a password generated.
    Please use the following password to proceed to installation:
    
    c638515e155c4eaaa193791cfbb94942
    
    This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
    
    *************************************************************
    *************************************************************
    *************************************************************
    
    2022-07-02 07:25:44.089+0000 [id=28]    INFO    jenkins.InitReactorRunner$1#onAttained: Completed initialization
    2022-07-02 07:25:44.099+0000 [id=22]    INFO    hudson.WebAppMain$3#run: Jenkins is fully up and running
    

看到上面的 `run: Jenkins is fully up and running` 信息就证明我们的 Jenkins 应用以前启动起来了。

然后我们可以通过 IngressRoute 中定义的域名 `jenkins.k8s.local`(需要做 DNS 解析或者在本地 `/etc/hosts` 中添加映射)来访问 jenkins 服务：

![jenkins unlock](https://picdn.youdianzhishi.com/images/1656749013819.png)

然后可以执行下面的命令获取解锁的管理员密码：
    
    
    $ kubectl exec -it jenkins-875f5bbb9-jlr46 -n kube-ops -- cat /var/jenkins_home/secrets/initialAdminPassword
    35b083de1d25409eaef57255e0da481a   # jenkins启动日志里面也有
    

然后跳过插件安装，选择默认安装插件过程会非常慢（也可以选择安装推荐的插件），点击右上角关闭选择插件，等配置好插件中心国内镜像源后再选择安装一些插件。

![ignore plugin install](https://picdn.youdianzhishi.com/images/20210525175154.png)

跳过后会直接进入 Jenkins 就绪页面，直接点击开始使用即可：

![jenkins ready](https://picdn.youdianzhishi.com/images/20210525175232.png)

进入主页后，首先安装中文插件，搜索 `Localization: Chinese`：

![Localization: Chinese](https://picdn.youdianzhishi.com/images/1656749451322.png)

安装重启完成后，点击最下方的 `Jenkins 中文社区` 进入页面配置插件代理：

![click jenkins chinese](https://picdn.youdianzhishi.com/images/1656750053327.png)

在页面中点击下方的 `设置更新中心地址` 链接：

![设置更新地址](https://picdn.youdianzhishi.com/images/20210525182810.png)

在新的页面最下面配置升级站点 URL 地址为 `https://updates.jenkins-zh.cn/update-center.json`（可能因为版本的问题会出现错误，可以尝试使用地址：`https://cdn.jsdelivr.net/gh/jenkins-zh/update-center-mirror/tsinghua/dynamic-stable-2.277.1/update-center.json` 进行测试），然后点击`提交`，最后点击`立即获取`：

![设置站点URL](https://picdn.youdianzhishi.com/images/1656751163865.png)

比如我们可以搜索安装 `Pipeline` 插件，配置完成后正常下载插件就应该更快了。

![install pipeline plugin](https://picdn.youdianzhishi.com/images/20210527144020.png)

## 架构

Jenkins 安装完成了，接下来我们不用急着就去使用，我们要了解下在 Kubernetes 环境下面使用 Jenkins 有什么好处。

我们知道持续构建与发布是我们日常工作中必不可少的一个步骤，目前大多公司都采用 Jenkins 集群来搭建符合需求的 CI/CD 流程，然而传统的 Jenkins Slave 一主多从方式会存在一些痛点，比如：

  * 主 Master 发生单点故障时，整个流程都不可用了
  * 每个 Slave 的配置环境不一样，来完成不同语言的编译打包等操作，但是这些差异化的配置导致管理起来非常不方便，维护起来也是比较费劲
  * 资源分配不均衡，有的 Slave 要运行的 job 出现排队等待，而有的 Slave 处于空闲状态
  * 资源有浪费，每台 Slave 可能是物理机或者虚拟机，当 Slave 处于空闲状态时，也不会完全释放掉资源。



正因为上面的这些种种痛点，我们渴望一种更高效更可靠的方式来完成这个 CI/CD 流程，而 Docker 虚拟化容器技术能很好的解决这个痛点，又特别是在 Kubernetes 集群环境下面能够更好来解决上面的问题，下图是基于 Kubernetes 搭建 Jenkins 集群的简单示意图：

![k8s jenkins slave](https://picdn.youdianzhishi.com/images/1656750648108.png)

从图上可以看到 `Jenkins Master` 和 `Jenkins Slave` 以 Pod 形式运行在 Kubernetes 集群的 Node 上，Master 运行在其中一个节点，并且将其配置数据存储到一个 Volume 上去，Slave 运行在各个节点上，并且它不是一直处于运行状态，它会按照需求动态的创建并自动删除。

这种方式的工作流程大致为：当 Jenkins Master 接受到 Build 请求时，会根据配置的 Label 动态创建一个运行在 Pod 中的 Jenkins Slave 并注册到 Master 上，当运行完 Job 后，这个 Slave 会被注销并且这个 Pod 也会自动删除，恢复到最初状态。

那么我们使用这种方式带来了哪些好处呢？

  * **服务高可用** ，当 Jenkins Master 出现故障时，Kubernetes 会自动创建一个新的 Jenkins Master 容器，并且将 Volume 分配给新创建的容器，保证数据不丢失，从而达到集群服务高可用。
  * **动态伸缩** ，合理使用资源，每次运行 Job 时，会自动创建一个 Jenkins Slave，Job 完成后，Slave 自动注销并删除容器，资源自动释放，而且 Kubernetes 会根据每个资源的使用情况，动态分配 Slave 到空闲的节点上创建，降低出现因某节点资源利用率高，还排队等待在该节点的情况。
  * **扩展性好** ，当 Kubernetes 集群的资源严重不足而导致 Job 排队等待时，可以很容易的添加一个 Kubernetes Node 到集群中，从而实现扩展。 是不是以前我们面临的种种问题在 Kubernetes 集群环境下面是不是都没有了啊？看上去非常完美。



## 配置

接下来我们就需要来配置 Jenkins，让他能够动态的生成 Slave 的 Pod。

第 1 步. 我们需要安装 [kubernetes 插件](https://github.com/jenkinsci/kubernetes-plugin)， 点击 Manage Jenkins -> Manage Plugins -> Available -> Kubernetes 勾选安装即可。

![kubernetes plugin](https://picdn.youdianzhishi.com/images/1656750693236.png)

第 2 步. 安装完毕后，进入 `http://jenkins.k8s.local/configureClouds/` 页面：

![new kubernetes plugin config](https://picdn.youdianzhishi.com/images/1656751203450.png)

在该页面我们可以点击 `Add a new cloud` -> 选择 `Kubernetes`，首先点击 `Kubernetes Cloud details...` 按钮进行配置：

![kubernetes plugin config](https://picdn.youdianzhishi.com/images/1656751233709.png)

首先配置连接 Kubernetes APIServer 的地址，由于我们的 Jenkins 运行在 Kubernetes 集群中，所以可以使用 Service 的 DNS 形式进行连接 `https://kubernetes.default.svc.cluster.local`：

![jenkins k8s apiserver](https://picdn.youdianzhishi.com/images/1656751314002.png)

注意 namespace，我们这里填 kube-ops，然后点击 `Test Connection`，如果出现 `Connected to Kubernetes...` 的提示信息证明 Jenkins 已经可以和 Kubernetes 系统正常通信了。

然后下方的 Jenkins URL 地址：`http://jenkins.kube-ops.svc.cluster.local:8080`，这里的格式为：`服务名.namespace.svc.cluster.local:8080`，根据上面创建的 jenkins 的服务名填写，包括下面的 Jenkins 通道，默认是 50000 端口（要注意是 TCP，所以不要填写 http）：

![jenkins url](https://picdn.youdianzhishi.com/images/1656751376150.png)

第 3 步. 点击最下方的 `Pod Templates` 按钮用于配置 Jenkins Slave 运行的 Pod 模板，命名空间我们同样是用 kube-ops，Labels 这里也非常重要，对于后面执行 Job 的时候需要用到该值。

![slave pod template](https://picdn.youdianzhishi.com/images/1656751455540.png)

然后配置下面的容器模板，我们这里使用的是 `cnych/jenkins:jnlp6` 这个镜像，这个镜像是在官方的 jnlp 镜像基础上定制的，加入了 docker、kubectl 等一些实用的工具`。

![jnlp container template](https://picdn.youdianzhishi.com/images/1656751538664.png)

注意

容器的名称必须是 `jnlp`，这是默认拉起的容器，另外需要将 `运行的命令` 和 `命令参数` 的值都删除掉，否则会失败。

由于 jnlp 容器中只是 docker cli，需要 docker daemon 才能正常使用，我们通常情况下的做法是将宿主机上的 docker sock 文件 `/var/run/docker.sock` 挂载到容器中，但是我们现在的 Kubernetes 集群使用的是 containerd 这种容器运行时，节点上没有 docker daemon。我们可以单独以 Pod 的形式在集群中跑一个 docker daemon 的服务，对应的资源清单如下所示：
    
    
    # docker-dind.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: docker-dind
      name: docker-dind-data
      namespace: kube-ops
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: local-path
      resources:
        requests:
          storage: 5Gi
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: docker-dind
      namespace: kube-ops
      labels:
        app: docker-dind
    spec:
      selector:
        matchLabels:
          app: docker-dind
      template:
        metadata:
          labels:
            app: docker-dind
        spec:
          containers:
            - image: docker:dind
              name: docker-dind
              args:
                - --registry-mirror=https://ot2k4d59.mirror.aliyuncs.com/ # 指定一个镜像加速器地址
              env:
                - name: DOCKER_DRIVER
                  value: overlay2
                - name: DOCKER_HOST
                  value: tcp://0.0.0.0:2375
                - name: DOCKER_TLS_CERTDIR # 禁用 TLS（最好别禁用）
                  value: ""
              volumeMounts:
                - name: docker-dind-data-vol # 持久化docker根目录
                  mountPath: /var/lib/docker/
              ports:
                - name: daemon-port
                  containerPort: 2375
              securityContext:
                privileged: true # 需要设置成特权模式
          volumes:
            - name: docker-dind-data-vol
              persistentVolumeClaim:
                claimName: docker-dind-data
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: docker-dind
      namespace: kube-ops
      labels:
        app: docker-dind
    spec:
      ports:
        - port: 2375
          targetPort: 2375
      selector:
        app: docker-dind
    

直接创建上面的资源对象即可：
    
    
    $ kubectl apply -f docker-dind.yaml
    $ kubectl get pods -n kube-ops -l app=docker-dind
    NAME                           READY   STATUS    RESTARTS   AGE
    docker-dind-864ffd5887-zm7lr   1/1     Running   0          11m
    $ kubectl get svc -n kube-ops -l app=docker-dind
    NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    docker-dind   ClusterIP   10.97.122.46   <none>        2375/TCP   6m26s
    

然后我们可以通过设置环境变量 `DOCKER_HOST: tcp://docker-dind:2375` 去连接 docker dind 服务。

![docker dind 环境变量](https://picdn.youdianzhishi.com/images/1656752441436.png)

另外需要将目录 `/root/.kube` 挂载到容器的 `/root/.kube` 目录下面，这是为了让我们能够在 Pod 的容器中能够使用 `kubectl` 工具来访问我们的 Kubernetes 集群，方便我们后面在 `Slave Pod` 部署 Kubernetes 应用。

![slave pod volume](https://picdn.youdianzhishi.com/images/1656752521158.png)

另外如果在配置了后运行 Slave Pod 的时候出现了权限问题，这是因为 Jenkins Slave Pod 中没有配置权限，所以需要配置上 ServiceAccount，在 Slave Pod 配置的地方点击下面的高级，添加上对应的 ServiceAccount 即可：

![slave pod serviceAccount](https://picdn.youdianzhishi.com/images/20210527183334.png)

到这里我们的 Kubernetes 插件就算配置完成了，记得保存。

## 测试

Kubernetes 插件的配置工作完成了，接下来我们就来添加一个 Job 任务，看是否能够在 Slave Pod 中执行，任务执行完成后看 Pod 是否会被销毁。

在 Jenkins 首页点击 `新建任务`，创建一个测试的任务，输入任务名称，然后我们选择 `构建一个自由风格的软件项目` 类型的任务，注意在下面的 `Label Expression` 这里要填入 `ydzs-jnlp`，就是前面我们配置的 Slave Pod 中的 Label，这两个地方必须保持一致：

![slave pod label](https://picdn.youdianzhishi.com/images/1656752727922.png)

然后往下拉，在 `构建` 区域选择 `执行 shell`：

![slave pod execute shell](https://picdn.youdianzhishi.com/images/1656752763920.png)

然后输入我们测试命令
    
    
    echo "测试 Kubernetes 动态生成 jenkins slave"
    echo "==============docker in docker==========="
    docker info
    
    echo "=============kubectl============="
    kubectl get pods
    

最后点击保存。

![slave pod execute command](https://picdn.youdianzhishi.com/images/1656752803053.png)

现在我们直接在页面点击左侧的 `立即构建` 触发构建即可，然后观察 Kubernetes 集群中 Pod 的变化：
    
    
    $ kubectl get pods -n kube-ops
    NAME                           READY   STATUS              RESTARTS   AGE
    docker-dind-864ffd5887-zm7lr   1/1     Running             0          18m
    jenkins-875f5bbb9-jlr46        1/1     Running             0          104m
    jenkins-agent-vm2th            0/1     ContainerCreating   0          4s
    

我们可以看到在我们点击立刻构建的时候可以看到一个新的 Pod：`jenkins-agent-vm2th` 被创建了，这就是我们的 Jenkins Slave。任务执行完成后我们可以看到任务信息:

![slave pod demo](https://picdn.youdianzhishi.com/images/1656753029702.jpg)

到这里证明我们的任务已经构建完成，然后这个时候我们再去集群查看我们的 Pod 列表，发现 kube-ops 这个 namespace 下面已经没有之前的 Slave 这个 Pod 了。
    
    
    $ kubectl get pods -n kube-ops
    NAME                           READY   STATUS              RESTARTS   AGE
    docker-dind-864ffd5887-zm7lr   1/1     Running             0          18m
    jenkins-875f5bbb9-jlr46        1/1     Running             0          104m
    

到这里我们就完成了使用 Kubernetes 动态生成 Jenkins Slave 的方法。
