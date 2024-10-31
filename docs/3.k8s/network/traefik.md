# Traefik

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/network/traefik.md "编辑此页")

# Traefik

[Traefik](https://github.com/containous/traefik) 是一个开源的可以使服务发布变得轻松有趣的边缘路由器。它负责接收你系统的请求，然后使用合适的组件来对这些请求进行处理。

![traefik architecture](https://picdn.youdianzhishi.com/images/20201224174307.png)

除了众多的功能之外，Traefik 的与众不同之处还在于它会自动发现适合你服务的配置。当 Traefik 在检查你的服务时，会找到服务的相关信息并找到合适的服务来满足对应的请求。

Traefik 兼容所有主流的集群技术，比如 Kubernetes，Docker，Docker Swarm，AWS，Mesos，Marathon，等等；并且可以同时处理多种方式。（甚至可以用于在裸机上运行的比较旧的软件。）

使用 Traefik，不需要维护或者同步一个独立的配置文件：因为一切都会自动配置，实时操作的（无需重新启动，不会中断连接）。使用 Traefik，你可以花更多的时间在系统的开发和新功能上面，而不是在配置和维护工作状态上面花费大量时间。

## 核心概念

Traefik 是一个边缘路由器，是你整个平台的大门，拦截并路由每个传入的请求：它知道所有的逻辑和规则，这些规则确定哪些服务处理哪些请求；传统的反向代理需要一个配置文件，其中包含路由到你服务的所有可能路由，而 Traefik 会实时检测服务并自动更新路由规则，可以自动服务发现。

![traefik architecture overview](https://picdn.youdianzhishi.com/images/20201224174338.png)

首先，当启动 Traefik 时，需要定义 `entrypoints`（入口点），然后，根据连接到这些 entrypoints 的**路由** 来分析传入的请求，来查看他们是否与一组**规则** 相匹配，如果匹配，则路由可能会将请求通过一系列**中间件** 转换过后再转发到你的**服务** 上去。在了解 Traefik 之前有几个核心概念我们必须要了解：

  * `Providers` 用来自动发现平台上的服务，可以是编排工具、容器引擎或者 key-value 存储等，比如 Docker、Kubernetes、File
  * `Entrypoints` 监听传入的流量（端口等…），是网络入口点，它们定义了接收请求的端口（HTTP 或者 TCP）。
  * `Routers` 分析请求（host, path, headers, SSL, …），负责将传入请求连接到可以处理这些请求的服务上去。
  * `Services` 将请求转发给你的应用（load balancing, …），负责配置如何获取最终将处理传入请求的实际服务。
  * `Middlewares` 中间件，用来修改请求或者根据请求来做出一些判断（authentication, rate limiting, headers, ...），中间件被附件到路由上，是一种在请求发送到你的**服务** 之前（或者在服务的响应发送到客户端之前）调整请求的一种方法。



## 安装

由于 Traefik 2.X 版本和之前的 1.X 版本不兼容，我们这里选择功能更加强大的 2.X 版本来和大家进行讲解。

在 Traefik 中的配置可以使用两种不同的方式：

  * 动态配置：完全动态的路由配置
  * 静态配置：启动配置



`静态配置`中的元素（这些元素不会经常更改）连接到 providers 并定义 Treafik 将要监听的 entrypoints。

> 在 Traefik 中有三种方式定义静态配置：在配置文件中、在命令行参数中、通过环境变量传递

`动态配置`包含定义系统如何处理请求的所有配置内容，这些配置是可以改变的，而且是无缝热更新的，没有任何请求中断或连接损耗。

这里我们还是使用 Helm 来快速安装 traefik，首先获取 Helm Chart 包：
    
    
    ➜ git clone https://github.com/traefik/traefik-helm-chart
    ➜ cd traefik-helm-chart
    

创建一个定制的 values 配置文件：
    
    
    # ci/deployment-prod.yaml
    deployment:
      enabled: true
      kind: Deployment
    
    # 使用 IngressClass. Traefik 版本<2.3 或者 Kubernetes 版本 < 1.18.x 会被忽略
    ingressClass:
      # 还没有进行完整的单元测试，pending https://github.com/rancher/helm-unittest/pull/12
      enabled: true
      isDefaultClass: false
    
    ingressRoute: # 不用自动创建，我们自己处理
      dashboard:
        enabled: false
    
    #
    # 配置 providers
    #
    providers:
      kubernetesCRD: # 开启 crd provider
        enabled: true
        allowCrossNamespace: true # 是否允许跨命名空间
        allowExternalNameServices: true # 是否允许使用 ExternalName 的服务
    
      kubernetesIngress: # 开启 ingress provider
        enabled: true
        allowExternalNameServices: true
    
    logs:
      general:
        # format: json
        level: DEBUG
      access:
        enabled: true
    
    ports:
      web:
        port: 8000
        hostPort: 80 # 使用 hostport 模式
    
      websecure:
        port: 8443
        hostPort: 443 # 使用 hostport 模式
    
      metrics:
        port: 9100
        hostPort: 9101
    
    service: # host 模式就不需要创建 Service 了，云端环境可以用 Service 模式
      enabled: false
    
    resources:
      requests:
        cpu: "100m"
        memory: "100Mi"
      limits:
        cpu: "100m"
        memory: "100Mi"
    
    # tolerations:   # kubeadm 安装的集群默认情况下master是有污点，如果需要安装在master节点需要添加容忍
    # - key: "node-role.kubernetes.io/master"
    #   operator: "Equal"
    #   effect: "NoSchedule"
    
    nodeSelector: # 固定到node1这个边缘节点
      kubernetes.io/hostname: "node1"
    

这里我们使用 hostport 模式将 Traefik 固定到 master1 节点上，因为只有这个节点有外网 IP，所以我们这里 master1 是作为流量的入口点。直接使用上面的 values 文件安装 traefik：
    
    
    ➜ helm upgrade --install traefik ./traefik -f ./traefik/ci/deployment-prod.yaml --namespace kube-system
    Release "traefik" does not exist. Installing it now.
    NAME: traefik
    LAST DEPLOYED: Thu Dec 23 17:03:29 2021
    NAMESPACE: kube-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ➜ kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
    NAME                       READY   STATUS    RESTARTS   AGE
    traefik-684d76779f-wpp8n   1/1     Running   0          3m15s
    

安装完成后我们可以通过查看 Pod 的资源清单来了解 Traefik 的运行方式：
    
    
    ➜ kubectl get deploy -n kube-system traefik -o yaml
    apiVersion: apps/v1
    kind: Deployment
    ......
        spec:
          containers:
          - args:
            - --global.checknewversion
            - --global.sendanonymoususage
            - --entryPoints.metrics.address=:9100/tcp
            - --entryPoints.traefik.address=:9000/tcp
            - --entryPoints.web.address=:8000/tcp
            - --entryPoints.websecure.address=:8443/tcp
            - --api.dashboard=true
            - --ping=true
            - --metrics.prometheus=true
            - --metrics.prometheus.entrypoint=metrics
            - --providers.kubernetescrd
            - --providers.kubernetescrd.allowExternalNameServices=true
            - --providers.kubernetesingress
            - --providers.kubernetesingress.allowExternalNameServices=true
            - --log.level=DEBUG
            - --accesslog=true
            - --accesslog.fields.defaultmode=keep
            - --accesslog.fields.headers.defaultmode=drop
            image: traefik:2.5.4
    ......
    

其中 `entryPoints` 属性定义了 `web` 和 `websecure` 这两个入口点的，并开启 `kubernetesingress` 和 `kubernetescrd` 这两个 provider，也就是我们可以使用 Kubernetes 原本的 Ingress 资源对象，也可以使用 Traefik 自己扩展的 `IngressRoute` 这样的 CRD 资源对象。

我们可以首先创建一个用于 Dashboard 访问的 IngressRoute 资源清单：
    
    
    ➜ cat <<EOF | kubectl apply -f -
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-dashboard
      namespace: kube-system
    spec:
      entryPoints:
      - web
      routes:
      - match: Host(`traefik.qikqiak.com`)  # 指定域名
        kind: Rule
        services:
        - name: api@internal
          kind: TraefikService  # 引用另外的 Traefik Service
    EOF
    ➜ kubectl get ingressroute -n kube-system
    NAME                AGE
    traefik-dashboard   19m
    

其中的 `TraefikService` 是 `Traefik Service` 的一个 CRD 实现，这里我们使用的 `api@internal` 这个 `TraefikService`，表示我们访问的是 Traefik 内置的应用服务。

部署完成后我们可以通过在本地 `/etc/hosts` 中添加上域名 `traefik.qikqiak.com` 的映射即可访问 Traefik 的 Dashboard 页面了：

![traefik dashboard demo](https://picdn.youdianzhishi.com/images/20211223190345.png)

注意

另外需要注意的是默认情况下 Traefik 的 IngressRoute 已经允许跨 namespace 进行通信了，可以通过设置参数 `--providers.kubernetescrd.allowCrossNamespace=true` 开启（默认已经开启），开启后 IngressRoute 就可以引用 IngressRoute 命名空间以外的其他命名空间中的任何资源了。

如果要让 Traefik 去处理默认的 Ingress 资源对象，则我们就需要使用名为 `traefik`的 IngressClass 了，因为没有指定默认的：
    
    
    ➜ kubectl get ingressclass
    NAME      CONTROLLER                      PARAMETERS   AGE
    nginx     k8s.io/ingress-nginx            <none>       46h
    traefik   traefik.io/ingress-controller   <none>       122m
    

创建如下所示的一个 Ingress 资源对象，这里的核心是 `ingressClassName` 要指向 `traefik` 这个 IngressClass：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: my-nginx-by-traefik
      namespace: default
    spec:
      ingressClassName: traefik # 使用 traefk 的 IngressClass
      rules:
        - host: ngdemo-by-traefik.qikqiak.com # 将域名映射到 my-nginx 服务
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service: # 将所有请求发送到 my-nginx 服务的 80 端口
                    name: my-nginx
                    port:
                      number: 80
    

直接创建上面的资源对象即可：
    
    
    ➜  kubectl get ingress
    NAME                  CLASS     HOSTS                           ADDRESS         PORTS     AGE
    my-nginx              nginx     ngdemo.qikqiak.com              192.168.31.31   80        3d23h
    my-nginx-by-traefik   traefik   ngdemo-by-traefik.qikqiak.com                   80        4s
    

然后就可以正常访问 `ngdemo-by-traefik.qikqiak.com` 域名了：
    
    
    ➜  curl ngdemo-by-traefik.qikqiak.com
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
    html { color-scheme: light dark; }
    body { width: 35em; margin: 0 auto;
    font-family: Tahoma, Verdana, Arial, sans-serif; }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    
    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>
    
    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>
    

## ACME

Traefik 通过扩展 CRD 的方式来扩展 Ingress 的功能，除了默认的用 Secret 的方式可以支持应用的 HTTPS 之外，还支持自动生成 HTTPS 证书。

比如现在我们有一个如下所示的 `whoami` 应用：
    
    
    apiVersion: v1
    kind: Service
    metadata:
      name: whoami
    spec:
      ports:
        - protocol: TCP
          name: web
          port: 80
      selector:
        app: whoami
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: whoami
      labels:
        app: whoami
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: whoami
      template:
        metadata:
          labels:
            app: whoami
        spec:
          containers:
            - name: whoami
              image: containous/whoami
              ports:
                - name: web
                  containerPort: 80
    

然后定义一个 IngressRoute 对象：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroute-demo
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/notls`)
          kind: Rule
          services:
            - name: whoami
              port: 80
    

通过 `entryPoints` 指定了我们这个应用的入口点是 `web`，也就是通过 80 端口访问，然后访问的规则就是要匹配 `who.qikqiak.com` 这个域名，并且具有 `/notls` 的路径前缀的请求才会被 `whoami` 这个 Service 所匹配。我们可以直接创建上面的几个资源对象，然后对域名做对应的解析后，就可以访问应用了：

![traefik whoami http demo](https://picdn.youdianzhishi.com/images/20211226180643.png)

在 `IngressRoute` 对象中我们定义了一些匹配规则，这些规则在 Traefik 中有如下定义方式：

![traefik route matcher](https://picdn.youdianzhishi.com/images/20201224141255.png)

如果我们需要用 HTTPS 来访问我们这个应用的话，就需要监听 `websecure` 这个入口点，也就是通过 443 端口来访问，同样用 HTTPS 访问应用必然就需要证书，这里我们用 `openssl` 来创建一个自签名的证书：
    
    
    ➜ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=who.qikqiak.com"
    

然后通过 Secret 对象来引用证书文件：
    
    
    # 要注意证书文件名称必须是 tls.crt 和 tls.key
    ➜ kubectl create secret tls who-tls --cert=tls.crt --key=tls.key
    

这个时候我们就可以创建一个 HTTPS 访问应用的 IngressRoute 对象了：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroute-tls-demo
    spec:
      entryPoints:
        - websecure
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
          kind: Rule
          services:
            - name: whoami
              port: 80
      tls:
        secretName: who-tls
    

创建完成后就可以通过 HTTPS 来访问应用了，由于我们是自签名的证书，所以证书是不受信任的：

![traefik whoami https demo](https://picdn.youdianzhishi.com/images/20211226181024.png)

除了手动提供证书的方式之外 Traefik 同样也支持使用 `Let’s Encrypt` 自动生成证书，要使用 `Let’s Encrypt` 来进行自动化 HTTPS，就需要首先开启 `ACME`，开启 `ACME` 需要通过静态配置的方式，也就是说可以通过环境变量、启动参数等方式来提供。

ACME 有多种校验方式 `tlsChallenge`、`httpChallenge` 和 `dnsChallenge` 三种验证方式，之前更常用的是 http 这种验证方式，关于这几种验证方式的使用可以查看文档：<https://www.qikqiak.com/traefik-book/https/acme/> 了解他们之间的区别。要使用 tls 校验方式的话需要保证 Traefik 的 443 端口是可达的，dns 校验方式可以生成通配符的证书，只需要配置上 DNS 解析服务商的 API 访问密钥即可校验。我们这里用 DNS 校验的方式来为大家说明如何配置 ACME。

我们可以重新修改 Helm 安装的 values 配置文件，添加如下所示的定制参数：
    
    
    # ci/deployment-prod.yaml
    additionalArguments:
      # 使用 dns 验证方式
      - --certificatesResolvers.ali.acme.dnsChallenge.provider=alidns
      # 先使用staging环境进行验证，验证成功后再使用移除下面一行的配置
      # - --certificatesResolvers.ali.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory
      # 邮箱配置
      - --certificatesResolvers.ali.acme.email=ych_1024@163.com
      # 保存 ACME 证书的位置
      - --certificatesResolvers.ali.acme.storage=/data/acme.json
    
    envFrom:
      - secretRef:
          name: traefik-alidns-secret
          # ALICLOUD_ACCESS_KEY
          # ALICLOUD_SECRET_KEY
          # ALICLOUD_REGION_ID
    
    persistence:
      enabled: true # 开启持久化
      accessMode: ReadWriteOnce
      size: 128Mi
      path: /data
    
    # 由于上面持久化了ACME的数据，需要重新配置下面的安全上下文
    securityContext:
      readOnlyRootFilesystem: false
      runAsGroup: 0
      runAsUser: 0
      runAsNonRoot: false
    

这样我们可以通过设置 `--certificatesresolvers.ali.acme.dnschallenge.provider=alidns` 参数来指定指定阿里云的 DNS 校验，要使用阿里云的 DNS 校验我们还需要配置 3 个环境变量：`ALICLOUD_ACCESS_KEY`、`ALICLOUD_SECRET_KEY`、`ALICLOUD_REGION_ID`，分别对应我们平时开发阿里云应用的时候的密钥，可以登录阿里云后台 <https://ram.console.aliyun.com/manage/ak> 获取，由于这是比较私密的信息，所以我们用 Secret 对象来创建：
    
    
    ➜ kubectl create secret generic traefik-alidns-secret --from-literal=ALICLOUD_ACCESS_KEY=<aliyun ak> --from-literal=ALICLOUD_SECRET_KEY=<aliyun sk> --from-literal=ALICLOUD_REGION_ID=cn-beijing -n kube-system
    

创建完成后将这个 Secret 通过环境变量配置到 Traefik 的应用中，还有一个值得注意的是验证通过的证书我们这里存到 `/data/acme.json` 文件中，我们一定要将这个文件持久化，否则每次 Traefik 重建后就需要重新认证，而 `Let’s Encrypt` 本身校验次数是有限制的。所以我们在 values 中重新开启了数据持久化，不过开启过后需要我们提供一个可用的 PV 存储，由于我们将 Traefik 固定到 master1 节点上的，所以我们可以创建一个 hostpath 类型的 PV（后面会详细讲解）：
    
    
    ➜ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: traefik
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 128Mi
      hostPath:
        path: /data/k8s/traefik
    EOF
    

然后使用如下所示的命令更新 Traefik：
    
    
    ➜ helm upgrade --install traefik ./traefik -f ./traefik/ci/deployment-prod.yaml --namespace kube-system
    

更新完成后现在我们来修改上面我们的 `whoami` 应用：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroute-tls-demo
    spec:
      entryPoints:
        - websecure
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
          kind: Rule
          services:
            - name: whoami
              port: 80
      tls:
        certResolver: ali
        domains:
          - main: "*.qikqiak.com"
    

其他的都不变，只需要将 tls 部分改成我们定义的 `ali` 这个证书解析器，如果我们想要生成一个通配符的域名证书的话可以定义 `domains` 参数来指定，然后更新 IngressRoute 对象，这个时候我们再去用 HTTPS 访问我们的应用（当然需要将域名在阿里云 DNS 上做解析）：

![traefik wildcard domain](https://picdn.youdianzhishi.com/images/20211226184210.png)

我们可以看到访问应用已经是受浏览器信任的证书了，查看证书我们还可以发现该证书是一个通配符的证书。

## 中间件

中间件是 Traefik2.x 中一个非常有特色的功能，我们可以根据自己的各种需求去选择不同的中间件来满足服务，Traefik 官方已经内置了许多不同功能的中间件，其中一些可以修改请求，头信息，一些负责重定向，一些添加身份验证等等，而且中间件还可以通过链式组合的方式来适用各种情况。

![traefik middleware overview](https://picdn.youdianzhishi.com/images/20201224172856.png)

### 跳转 https

同样比如上面我们定义的 whoami 这个应用，我们可以通过 `https://who.qikqiak.com/tls` 来访问到应用，但是如果我们用 `http` 来访问的话呢就不行了，就会 404 了，因为我们根本就没有简单 80 端口这个入口点，所以要想通过 `http` 来访问应用的话自然我们需要监听下 `web` 这个入口点：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroutetls-http
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
          kind: Rule
          services:
            - name: whoami
              port: 80
    

注意这里我们创建的 IngressRoute 的 entryPoints 是 `web`，然后创建这个对象，这个时候我们就可以通过 http 访问到这个应用了。

但是我们如果只希望用户通过 https 来访问应用的话呢？按照以前的知识，我们是不是可以让 http 强制跳转到 https 服务去，对的，在 Traefik 中也是可以配置强制跳转的，只是这个功能现在是通过中间件来提供的了。如下所示，我们使用 `redirectScheme` 中间件来创建提供强制跳转服务：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: redirect-https
    spec:
      redirectScheme:
        scheme: https
    

然后将这个中间件附加到 http 的服务上面去，因为 https 的不需要跳转：
    
    
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroutetls-http
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
          kind: Rule
          services:
            - name: whoami
              port: 80
          middlewares:
            - name: redirect-https
    

这个时候我们再去访问 http 服务可以发现就会自动跳转到 https 去了。

### URL Rewrite

接着我们再介绍如何使用 Traefik 来实现 URL Rewrite 操作，比如我们现部署一个 Nexus 应用，通过 IngressRoute 来暴露服务，对应的资源清单如下所示：
    
    
    # nexus.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nexus
      labels:
        app: nexus
    spec:
      selector:
        matchLabels:
          app: nexus
      template:
        metadata:
          labels:
            app: nexus
        spec:
          containers:
            - image: cnych/nexus:3.20.1
              imagePullPolicy: IfNotPresent
              name: nexus
              ports:
                - containerPort: 8081
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: nexus
      name: nexus
    spec:
      ports:
        - name: nexusport
          port: 8081
          targetPort: 8081
      selector:
        app: nexus
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: nexus
      namespace: kube-system # 和Service不在同一个命名空间
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: Host(`nexus.qikqiak.com`)
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
    

由于我们开启了 Traefik 的跨命名空间功能（参数 `--providers.kubernetescrd.allowCrossNamespace=true`），所以可以引用其他命名空间中的 Service 或者中间件，直接部署上面的应用即可:
    
    
    ➜ kubectl apply -f nexus.yaml
    ➜ kubectl get ingressroute -n kube-system
    NAME                AGE
    nexus               19h
    ➜ kubectl get pods -l app=nexus
    NAME                     READY   STATUS    RESTARTS   AGE
    nexus-6f78b79d4c-8xns6   1/1     Running   0          3m37s
    ➜ kubectl get svc -l app=nexus
    NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    nexus   ClusterIP   10.110.135.97   <none>        8081/TCP   50s
    

部署完成后，我们根据 `IngressRoute` 对象中的配置，只需要将域名 `nexus.qikqiak.com` 解析到 Traefik 的节点即可访问：

![nexus url](https://picdn.youdianzhishi.com/images/20211228161704.png)

到这里我们都可以很简单的来完成，同样的现在我们有一个需求是目前我们只有一个域名可以使用，但是我们有很多不同的应用需要暴露，这个时候我们就只能通过 PATH 路径来进行区分了，比如我们现在希望当我们访问 `http:/nexus.qikqiak.com/foo` 的时候就是访问的我们的 Nexus 这个应用，当路径是 `/bar` 开头的时候是其他应用，这种需求是很正常的，这个时候我们就需要来做 URL Rewrite 了。

首先我们使用 [StripPrefix](https://www.qikqiak.com/traefik-book/middlewares/stripprefix/) 这个中间件，这个中间件的功能是**在转发请求之前从路径中删除前缀** ，在使用中间件的时候我们只需要理解中间件操作的都是我们直接的请求即可，并不是真实的应用接收到请求过后来进行修改。

现在我们添加一个如下的中间件：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: strip-foo-path
      namespace: default # 注意这里的中间件我们定义在default命名空间下面的
    spec:
      stripPrefix:
        prefixes:
          - /foo
    

然后现在我们就需要从 `http:/nexus.qikqiak.com/foo` 请求中去匹配 `/foo` 的请求，把这个路径下面的请求应用到上面的中间件中去，因为最终我们的 Nexus 应用接收到的请求是不会带有 `/foo` 路径的，所以我们需要在请求到达应用之前将这个前缀删除，更新 IngressRoute 对象：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: nexus
      namespace: kube-system
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`) # 匹配 /foo 路径
          middlewares:
            - name: strip-foo-path
              namespace: default # 由于我们开启了traefik的跨命名空间功能，所以可以引用其他命名空间中的中间件
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
    

创建中间件更新完成上面的 IngressRoute 对象后，这个时候我们前往浏览器中访问 `http:/nexus.qikqiak.com/foo`，这个时候发现我们的页面任何样式都没有了：

![nexus rewrite url error](https://picdn.youdianzhishi.com/images/20211228162000.png)

我们通过 Chrome 浏览器的 Network 可以查看到 `/foo` 路径的请求是 200 状态码，但是其他的静态资源对象确全都是 404 了，这是为什么呢？我们仔细观察上面我们的 IngressRoute 资源对象，我们现在是不是只匹配了 `/foo` 的请求，而我们的静态资源是 `/static` 路径开头的，当然就匹配不到了，所以就出现了 404，所以我们只需要加上这个 `/static` 路径的匹配就可以了，同样更新 IngressRoute 对象：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: nexus
      namespace: kube-system
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`)
          middlewares:
            - name: strip-foo-path
              namespace: default
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
        - kind: Rule
          match: Host(`nexus.qikqiak.com`) && PathPrefix(`/static`) # 匹配 /static 的请求
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
    

然后更新 IngressRoute 资源对象，这个时候再次去访问应用，可以发现页面样式已经正常了，也可以正常访问应用了：

![nexus rewrite url error2](https://picdn.youdianzhishi.com/images/20211228162133.png)

但进入应用后发现还是有错误提示信息，通过 Network 分析发现还有一些 `/service` 开头的请求是 404，当然我们再加上这个前缀的路径即可：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: nexus
      namespace: kube-system
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`)
          middlewares:
            - name: strip-foo-path
              namespace: default
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
        - kind: Rule
          match: Host(`nexus.qikqiak.com`) && (PathPrefix(`/static`) || PathPrefix(`/service`)) # 匹配 /static 和 /service 的请求
          services:
            - kind: Service
              name: nexus
              namespace: default
              port: 8081
    

更新后，再次访问应用就已经完全正常了：

![nexus rewrite url ok](https://picdn.youdianzhishi.com/images/20211228162250.png)

Traefik2.X 版本中的中间件功能非常强大，基本上官方提供的系列中间件可以满足我们大部分需求了，其他中间件的用法，可以参考文档：<https://www.qikqiak.com/traefik-book/middlewares/overview/>。

## Traefik Pilot

虽然 Traefik 已经默认实现了很多中间件，可以满足大部分我们日常的需求，但是在实际工作中，用户仍然还是有自定义中间件的需求，这就 [Traefik Pilot](https://pilot.traefik.io/) 的功能了。

![pilot](https://picdn.youdianzhishi.com/images/20201225100314.png)

Traefik Pilot 是一个 SaaS 平台，和 Traefik 进行链接来扩展其功能，它提供了很多功能，通过一个全局控制面板和 Dashboard 来增强对 Traefik 的观测和控制：

  * Traefik 代理和代理组的网络活动的指标
  * 服务健康问题和安全漏洞警报
  * 扩展 Traefik 功能的插件



在 Traefik 可以使用 `Traefik Pilot` 的功能之前，必须先连接它们，我们只需要对 Traefik 的静态配置进行少量更改即可。

> Traefik 代理必须要能访问互联网才能连接到 `Traefik Pilot`，通过 HTTPS 在 443 端口上建立连接。

首先我们需要在 `Traefik Pilot` 主页上(https://pilot.traefik.io/)创建一个帐户，注册新的 `Traefik` 实例并开始使用 `Traefik Pilot`。登录后，可以通过选择 `Register New Traefik Instance`来创建新实例。

![创建实例](https://picdn.youdianzhishi.com/images/20201225100714.png)

另外，当我们的 Traefik 尚未连接到 `Traefik Pilot` 时，Traefik Web UI 中将出现一个响铃图标，我们可以选择 `Connect with Traefik Pilot` 导航到 Traefik Pilot UI 进行操作。

![Pilot UI](https://picdn.youdianzhishi.com/images/20201225100905.png)

登录完成后，`Traefik Pilot` 会生成一个新实例的令牌，我们需要将这个 Token 令牌添加到 Traefik 静态配置中。

![Pilot 配置](https://picdn.youdianzhishi.com/images/20201225101104.png)

我们这里就是在 `ci/deployment-prod.yaml` 文件中启用 Pilot 的配置：
    
    
    # ci/deployment-prod.yaml
    # Activate Pilot integration
    pilot:
      enabled: true
      token: "e079ea6e-536a-48c6-b3e3-f7cfaf94f477"
    

然后重新更新 Traefik：
    
    
    ➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./traefik/ci/deployment-prod.yaml
    

更新完成后，我们在 Traefik 的 Web UI 中就可以看到 Traefik Pilot UI 相关的信息了。

![更新完成](https://picdn.youdianzhishi.com/images/20201225101951.png)

接下来我们就可以在 Traefik Pilot 的插件页面选择我们想要使用的插件，比如我们这里使用 [Demo Plugin](https://github.com/traefik/plugindemo) 这个插件。

![Demo 插件](https://picdn.youdianzhishi.com/images/20201225102230.png)

点击右上角的 `Install Plugin` 按钮安装插件会弹出一个对话框提示我们如何安装。

![插件提示](https://picdn.youdianzhishi.com/images/20201225102357.png)

首先我们需要将当前 Traefik 注册到 Traefik Pilot（已完成），然后需要以静态配置的方式添加这个插件到 Traefik 中，这里我们同样更新 `ci/deployment-prod.yaml` 文件中的 Values 值即可：
    
    
    # ci/deployment-prod.yaml
    # Activate Pilot integration
    pilot:
      enabled: true
      token: "e079ea6e-536a-48c6-b3e3-f7cfaf94f477"
    
    additionalArguments:
      # 添加 demo plugin 的支持
      - --experimental.plugins.plugindemo.modulename=github.com/traefik/plugindemo
      - --experimental.plugins.plugindemo.version=v0.2.1
    # 其他配置
    

同样重新更新 Traefik：
    
    
    ➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./ci/deployment-prod.yaml
    

更新完成后创建一个如下所示的 Middleware 对象：
    
    
    ➜ cat <<EOF | kubectl apply -f -
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: myplugin
    spec:
      plugin:
        plugindemo:  # 插件名
          Headers:
            X-Demo: test
            Foo: bar
    EOF
    

然后添加到上面的 whoami 应用的 IngressRoute 对象中去：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroute-demo
      namespace: default
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/notls`)
          kind: Rule
          services:
            - name: whoami # K8s Service
              port: 80
          middlewares:
            - name: myplugin # 使用上面新建的 middleware
    

更新完成后，当我们去访问 `http://who.qikqiak.com/notls` 的时候就可以看到新增了两个上面插件中定义的两个 Header。

![自定义插件显示](https://picdn.youdianzhishi.com/images/20201225104027.png)

当然除了使用 Traefik Pilot 上开发者提供的插件之外，我们也可以根据自己的需求自行开发自己的插件，可以自行参考文档：<https://doc.traefik.io/traefik-pilot/plugins/plugin-dev/>。

## 私有插件

上面我们介绍了可以使用 Traefik Pilot 来使用插件，但是这是一个 SaaS 服务平台，对于大部分企业场景下面不是很适用，我们更多的场景下需要在本地环境加载插件，为解决这个问题，在 Traefik v2.5 版本后，就提供了一种直接从本地存储目录加载插件的新方法，不需要启用 Traefik Pilot，只需要将插件源码放入一个名为 `/plugins-local` 的新目录，相对于当前工作目录去创建这个目录，比如我们直接使用的是 traefik 的 docker 镜像，则入口点则是根目录 `/`，Traefik 本身会去构建你的插件，所以我们要做的就是编写源代码，并把它放在正确的目录下，让 Traefik 来加载它即可。

需要注意的是由于在每次启动的时候插件只加载一次，所以如果我们希望重新加载你的插件源码的时候需要重新启动 Traefik。

下面我们使用一个简单的自定义插件示例来说明如何使用私有插件。首先我们定义一个名为 `Dockerfile.demo` 的 Dockerfile 文件，先从 git 仓库中克隆插件源码，然后以 `traefik:v2.5` 为基础镜像，将插件源码拷贝刀 `/plugins-local` 目录，如下所示：
    
    
    FROM alpine:3
    ARG PLUGIN_MODULE=github.com/traefik/plugindemo
    ARG PLUGIN_GIT_REPO=https://github.com/traefik/plugindemo.git
    ARG PLUGIN_GIT_BRANCH=master
    RUN apk add --update git && \
        git clone ${PLUGIN_GIT_REPO} /plugins-local/src/${PLUGIN_MODULE} \
          --depth 1 --single-branch --branch ${PLUGIN_GIT_BRANCH}
    
    FROM traefik:v2.5
    COPY --from=0 /plugins-local /plugins-local
    

我们这里使用的演示插件和上面 Pilot 中演示的是同一个插件，我们可以通过该插件去自定义请求头信息。

然后在 `Dockerfile.demo` 目录下面，构建镜像：
    
    
    ➜ docker build -f Dockerfile.demo -t cnych/traefik-private-demo-plugin:2.5.4 .
    # 推送到镜像仓库
    ➜ docker push cnych/traefik-private-demo-plugin:2.5.4
    

镜像构建完成后就可以使用这个镜像来测试 demo 插件了，同样我们这里直接去覆盖的 Values 文件，更新 `ci/deployment-prod.yaml` 文件中的 Values 值，将镜像修改成上面我们自定义的镜像地址：
    
    
    # ci/deployment-prod.yaml
    image:
      name: cnych/traefik-private-demo-plugin
      tag: 2.5.4
    
    # 其他省略
    
    # 不需要开启 pilot 了
    pilot:
      enabled: false
    
    additionalArguments:
      # 添加 demo plugin 的本地支持
      - --experimental.localPlugins.plugindemo.moduleName=github.com/traefik/plugindemo
    # 其他省略
    

注意上面我们添加 Traefik 的启动参数的时候使用的 `--experimental.localPlugins`。然后重新更新 Traefik：
    
    
    ➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./ci/deployment-prod.yaml
    

更新完成后就可以使用我们的私有插件来创建一个 Middleware 对象了：
    
    
    ➜ cat <<EOF | kubectl apply -f -
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: my-private-plugin
    spec:
      plugin:
        plugindemo:  # 插件名
          Headers:
            X-Demo: private-demo
            Foo: bar
    EOF
    

然后添加到上面的 whoami 应用的 IngressRoute 对象中去：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: ingressroute-demo
      namespace: default
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`who.qikqiak.com`) && PathPrefix(`/notls`)
          kind: Rule
          services:
            - name: whoami # K8s Service
              port: 80
          middlewares:
            - name: my-private-plugin # 使用上面新建的 middleware
    

更新上面的资源对象后，我们再去访问 `http://who.qikqiak.com/notls` 就可以看到新增了两个上面插件中定义的两个 Header，证明我们的私有插件配置成功了：

![自定义插件显示](https://picdn.youdianzhishi.com/images/20211227110109.png)

## 灰度发布

Traefik2.0 的一个更强大的功能就是灰度发布，灰度发布我们有时候也会称为金丝雀发布（Canary），主要就是让一部分测试的服务也参与到线上去，经过测试观察看是否符号上线要求。

![canary deployment](https://picdn.youdianzhishi.com/images/20201224172918.png)

比如现在我们有两个名为 `appv1` 和 `appv2` 的服务，我们希望通过 Traefik 来控制我们的流量，将 3⁄4 的流量路由到 appv1，¼ 的流量路由到 appv2 去，这个时候就可以利用 Traefik2.0 中提供的**带权重的轮询（WRR）** 来实现该功能，首先在 Kubernetes 集群中部署上面的两个服务。为了对比结果我们这里提供的两个服务一个是 whoami，一个是 nginx，方便测试。

appv1 服务的资源清单如下所示：
    
    
    # appv1.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: appv1
    spec:
      selector:
        matchLabels:
          app: appv1
      template:
        metadata:
          labels:
            use: test
            app: appv1
        spec:
          containers:
            - name: whoami
              image: containous/whoami
              ports:
                - containerPort: 80
                  name: portv1
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: appv1
    spec:
      selector:
        app: appv1
      ports:
        - name: http
          port: 80
          targetPort: portv1
    

appv2 服务的资源清单如下所示：
    
    
    # appv2.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: appv2
    spec:
      selector:
        matchLabels:
          app: appv2
      template:
        metadata:
          labels:
            use: test
            app: appv2
        spec:
          containers:
            - name: nginx
              image: nginx
              ports:
                - containerPort: 80
                  name: portv2
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: appv2
    spec:
      selector:
        app: appv2
      ports:
        - name: http
          port: 80
          targetPort: portv2
    

直接创建上面两个服务：
    
    
    ➜ kubectl apply -f appv1.yaml
    ➜ kubectl apply -f appv2.yaml
    # 通过下面的命令可以查看服务是否运行成功
    ➜ kubectl get pods -l use=test
    NAME                     READY   STATUS    RESTARTS   AGE
    appv1-58f856c665-shm9j   1/1     Running   0          12s
    appv2-ff5db55cf-qjtrf    1/1     Running   0          12s
    

在 Traefik2.1 中新增了一个 `TraefikService` 的 CRD 资源，我们可以直接利用这个对象来配置 WRR，之前的版本需要通过 File Provider，比较麻烦，新建一个描述 WRR 的资源清单：
    
    
    # wrr.yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: TraefikService
    metadata:
      name: app-wrr
    spec:
      weighted:
        services:
          - name: appv1
            weight: 3 # 定义权重
            port: 80
            kind: Service # 可选，默认就是 Service
          - name: appv2
            weight: 1
            port: 80
    

然后为我们的灰度发布的服务创建一个 IngressRoute 资源对象：
    
    
    # wrr-ingressroute.yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: wrr-ingressroute
      namespace: default
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`wrr.qikqiak.com`)
          kind: Rule
          services:
            - name: app-wrr
              kind: TraefikService
    

不过需要注意的是现在我们配置的 Service 不再是直接的 Kubernetes 对象了，而是上面我们定义的 TraefikService 对象，直接创建上面的两个资源对象，这个时候我们对域名 `wrr.qikqiak.com` 做上解析，去浏览器中连续访问 4 次，我们可以观察到 appv1 这应用会收到 3 次请求，而 appv2 这个应用只收到 1 次请求，符合上面我们的 `3:1` 的权重配置。

![traefik wrr demo](https://picdn.youdianzhishi.com/images/20201224172948.png)

## 流量复制

除了灰度发布之外，Traefik 2.0 还引入了流量镜像服务，是一种可以将流入流量复制并同时将其发送给其他服务的方法，镜像服务可以获得给定百分比的请求同时也会忽略这部分请求的响应。

![traefik mirror](https://picdn.youdianzhishi.com/images/20201224173010.png)

现在我们部署两个 whoami 的服务，资源清单文件如下所示：
    
    
    apiVersion: v1
    kind: Service
    metadata:
      name: v1
    spec:
      ports:
        - protocol: TCP
          name: web
          port: 80
      selector:
        app: v1
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: v1
      labels:
        app: v1
    spec:
      selector:
        matchLabels:
          app: v1
      template:
        metadata:
          labels:
            app: v1
        spec:
          containers:
            - name: v1
              image: nginx
              ports:
                - name: web
                  containerPort: 80
    
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: v2
    spec:
      ports:
        - protocol: TCP
          name: web
          port: 80
      selector:
        app: v2
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: v2
      labels:
        app: v2
    spec:
      selector:
        matchLabels:
          app: v2
      template:
        metadata:
          labels:
            app: v2
        spec:
          containers:
            - name: v2
              image: nginx
              ports:
                - name: web
                  containerPort: 80
    

直接创建上面的资源对象：
    
    
    ➜ kubectl get pods
    NAME                                      READY   STATUS    RESTARTS   AGE
    v1-77cfb86999-wfbl2                       1/1     Running   0          94s
    v2-6f45d498b7-g6qjt                       1/1     Running   0          91s
    ➜ kubectl get svc
    NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
    v1              ClusterIP   10.96.218.173   <none>        80/TCP      99s
    v2              ClusterIP   10.99.98.48     <none>        80/TCP      96s
    

现在我们创建一个 IngressRoute 对象，将服务 v1 的流量复制 50% 到服务 v2，如下资源对象所示：
    
    
    # mirror-ingress-route.yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: TraefikService
    metadata:
      name: app-mirror
    spec:
      mirroring:
        name: v1 # 发送 100% 的请求到 K8S 的 Service "v1"
        port: 80
        mirrors:
          - name: v2 # 然后复制 50% 的请求到 v2
            percent: 50
            port: 80
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: mirror-ingress-route
      namespace: default
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`mirror.qikqiak.com`)
          kind: Rule
          services:
            - name: app-mirror
              kind: TraefikService # 使用声明的 TraefikService 服务，而不是 K8S 的 Service
    

然后直接创建这个资源对象即可：
    
    
    ➜ kubectl apply -f mirror-ingress-route.yaml
    

这个时候我们在浏览器中去连续访问 4 次 `mirror.qikqiak.com` 可以发现有一半的请求也出现在了 `v2` 这个服务中： ![traefik mirror demo](https://picdn.youdianzhishi.com/images/20201224173045.png)

## TCP

另外 Traefik2.X 已经支持了 TCP 服务的，下面我们以 mongo 为例来了解下 Traefik 是如何支持 TCP 服务得。

### 简单 TCP 服务

首先部署一个普通的 mongo 服务，资源清单文件如下所示：（mongo.yaml）
    
    
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongo-traefik
      labels:
        app: mongo-traefik
    spec:
      selector:
        matchLabels:
          app: mongo-traefik
      template:
        metadata:
          labels:
            app: mongo-traefik
        spec:
          containers:
            - name: mongo
              image: mongo:4.0
              ports:
                - containerPort: 27017
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mongo-traefik
    spec:
      selector:
        app: mongo-traefik
      ports:
        - port: 27017
    

直接创建 mongo 应用：
    
    
    ➜ kubectl apply -f mongo.yaml
    deployment.apps/mongo-traefik created
    service/mongo-traefik created
    

创建成功后就可以来为 mongo 服务配置一个路由了。由于 Traefik 中使用 TCP 路由配置需要 `SNI`，而 `SNI` 又是依赖 `TLS` 的，所以我们需要配置证书才行，如果没有证书的话，我们可以使用通配符 `*` 进行配置，我们这里创建一个 `IngressRouteTCP` 类型的 CRD 对象（前面我们就已经安装了对应的 CRD 资源）：
    
    
    # mongo-ingressroute-tcp.yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRouteTCP
    metadata:
      name: mongo-traefik-tcp
    spec:
      entryPoints:
        - mongo
      routes:
        - match: HostSNI(`*`)
          services:
            - name: mongo-traefik
              port: 27017
    

要注意的是这里的 `entryPoints` 部分，是根据我们启动的 Traefik 的静态配置中的 entryPoints 来决定的，我们当然可以使用前面我们定义得 80 和 443 这两个入口点，但是也可以可以自己添加一个用于 mongo 服务的专门入口点，更新 `values-prod.yaml` 文件，新增 mongo 这个入口点：
    
    
    # values-prod.yaml
    ports:
      web:
        port: 8000
        hostPort: 80
      websecure:
        port: 8443
        hostPort: 443
      mongo:
        port: 27017
        hostPort: 27017
    

然后更新 Traefik 即可：
    
    
    ➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./ci/deployment-prod.yaml
    

这里给入口点添加 `hostPort` 是为了能够通过节点的端口访问到服务，关于 entryPoints 入口点的更多信息，可以查看文档 [entrypoints](https://www.qikqiak.com/traefik-book/routing/entrypoints/) 了解更多信息。

然后更新 Traefik 后我们就可以直接创建上面的资源对象：
    
    
    ➜ kubectl apply -f mongo-ingressroute-tcp.yaml
    

创建完成后，同样我们可以去 Traefik 的 Dashboard 页面上查看是否生效：

![traefik-tcp-mongo-1](https://picdn.youdianzhishi.com/images/20201224173115.png)

然后我们配置一个域名 `mongo.local` 解析到 Traefik 所在的节点，然后通过 27017 端口来连接 mongo 服务：
    
    
    ➜ mongo --host mongo.local --port 27017
    mongo(75243,0x1075295c0) malloc: *** malloc_zone_unregister() failed for 0x7fffa56f4000
    MongoDB shell version: 2.6.1
    connecting to: mongo.local:27017/test
    > show dbs
    admin   0.000GB
    config  0.000GB
    local   0.000GB
    

到这里我们就完成了将 mongo（TCP）服务暴露给外部用户了。

### 带 TLS 证书的 TCP

上面我们部署的 mongo 是一个普通的服务，然后用 Traefik 代理的，但是有时候为了安全 mongo 服务本身还会使用 TLS 证书的形式提供服务，下面是用来生成 mongo tls 证书的脚本文件：（generate-certificates.sh）
    
    
    #!/bin/bash
    #
    # From https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
    
    set -eu -o pipefail
    
    DOMAINS="${1}"
    CERTS_DIR="${2}"
    [ -d "${CERTS_DIR}" ]
    CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd -P)"
    
    GENERATION_DIRNAME="$(echo "${DOMAINS}" | cut -d, -f1)"
    
    rm -rf "${CERTS_DIR}/${GENERATION_DIRNAME:?}" "${CERTS_DIR}/certs"
    
    echo "== Checking Requirements..."
    command -v go >/dev/null 2>&1 || echo "Golang is required"
    command -v minica >/dev/null 2>&1 || go get github.com/jsha/minica >/dev/null
    
    echo "== Generating Certificates for the following domains: ${DOMAINS}..."
    cd "${CERTS_DIR}"
    minica --ca-cert "${CURRENT_DIR}/minica.pem" --ca-key="${CURRENT_DIR}/minica-key.pem" --domains="${DOMAINS}"
    mv "${GENERATION_DIRNAME}" "certs"
    cat certs/key.pem certs/cert.pem > certs/mongo.pem
    
    echo "== Certificates Generated in the directory ${CERTS_DIR}/certs"
    

将上面证书放置到 certs 目录下面，然后我们新建一个 `02-tls-mongo` 的目录，在该目录下面执行如下命令来生成证书：
    
    
    ➜ bash ../certs/generate-certificates.sh mongo.local .
    == Checking Requirements...
    == Generating Certificates for the following domains: mongo.local...
    

最后的目录如下所示，在 `02-tls-mongo` 目录下面会生成包含证书的 certs 目录：
    
    
    ➜ tree .
    .
    ├── 01-mongo
    │   ├── mongo-ingressroute-tcp.yaml
    │   └── mongo.yaml
    ├── 02-tls-mongo
    │   └── certs
    │       ├── cert.pem
    │       ├── key.pem
    │       └── mongo.pem
    └── certs
        ├── generate-certificates.sh
        ├── minica-key.pem
        └── minica.pem
    

在 `02-tls-mongo/certs` 目录下面执行如下命令通过 Secret 来包含证书内容：
    
    
    ➜ kubectl create secret tls traefik-mongo-certs --cert=cert.pem --key=key.pem
    secret/traefik-mongo-certs created
    

然后重新更新 `IngressRouteTCP` 对象，增加 TLS 配置：
    
    
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRouteTCP
    metadata:
      name: mongo-traefik-tcp
    spec:
      entryPoints:
        - mongo
      routes:
        - match: HostSNI(`mongo.local`)
          services:
            - name: mongo-traefik
              port: 27017
      tls:
        secretName: traefik-mongo-certs
    

同样更新后，现在我们直接去访问应用就会被 hang 住，因为我们没有提供证书：
    
    
    ➜ mongo --host mongo.local --port 27017
    MongoDB shell version: 2.6.1
    connecting to: mongo1.local:27017/test
    

这个时候我们可以带上证书来进行连接：
    
    
    ➜ mongo --host mongo.local --port 27017 --ssl --sslCAFile=../certs/minica.pem --sslPEMKeyFile=./certs/mongo.pem
    MongoDB shell version v4.0.3
    connecting to: mongodb://mongo.local:27017/
    Implicit session: session { "id" : UUID("e7409ef6-8ebe-4c5a-9642-42059bdb477b") }
    MongoDB server version: 4.0.14
    ......
    > show dbs;
    admin   0.000GB
    config  0.000GB
    local   0.000GB
    

可以看到现在就可以连接成功了，这样就完成了一个使用 TLS 证书代理 TCP 服务的功能，这个时候如果我们使用其他的域名去进行连接就会报错了，因为现在我们指定的是特定的 HostSNI：
    
    
    ➜ mongo --host mongo.k8s.local --port 27017 --ssl --sslCAFile=../certs/minica.pem --sslPEMKeyFile=./certs/mongo.pem
    MongoDB shell version v4.0.3
    connecting to: mongodb://mongo.k8s.local:27017/
    2019-12-29T15:03:52.424+0800 E NETWORK  [js] SSL peer certificate validation failed: Certificate trust failure: CSSMERR_TP_NOT_TRUSTED; connection rejected
    2019-12-29T15:03:52.429+0800 E QUERY    [js] Error: couldn't connect to server mongo.qikqiak.com:27017, connection attempt failed: SSLHandshakeFailed: SSL peer certificate validation failed: Certificate trust failure: CSSMERR_TP_NOT_TRUSTED; connection rejected :
    connect@src/mongo/shell/mongo.js:257:13
    @(connect):1:6
    exception: connect failed
    

## UDP

此外 Traefik2.3.x 版本也已经提供了对 UDP 的支持，所以我们可以用于诸如 DNS 解析的服务提供负载。同样首先部署一个如下所示的 UDP 服务：
    
    
    apiVersion: v1
    kind: Service
    metadata:
      name: whoamiudp
    spec:
      ports:
        - protocol: UDP
          name: udp
          port: 8080
      selector:
        app: whoamiudp
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: whoamiudp
      labels:
        app: whoamiudp
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: whoamiudp
      template:
        metadata:
          labels:
            app: whoamiudp
        spec:
          containers:
            - name: whoamiudp
              image: containous/whoamiudp
              ports:
                - name: udp
                  containerPort: 8080
    

直接部署上面的应用，部署完成后我们需要在 Traefik 中定义一个 UDP 的 entryPoint 入口点，修改我们部署 Traefik 的 `values-prod.yaml` 文件，增加 UDP 协议的入口点：
    
    
    # Configure ports
    ports:
      web:
        port: 8000
        hostPort: 80
      websecure:
        port: 8443
        hostPort: 443
      mongo:
        port: 27017
        hostPort: 27017
      udpep:
        port: 18080
        hostPort: 18080
        protocol: UDP
    

我们这里定义了一个名为 udpep 的入口点，但是 protocol 协议是 UDP（此外 TCP 和 UDP 共用同一个端口也是可以的，但是协议一定要声明为不一样），然后重新更新 Traefik：
    
    
    ➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./ci/deployment-prod.yaml
    

更新完成后我们可以导出 Traefik 部署的资源清单文件来检测是否增加上了 UDP 的入口点：
    
    
    ➜ kubectl get deploy traefik -n kube-system -o yaml
    ......
    containers:
    - args:
      - --entryPoints.mongo.address=:27017/tcp
      - --entryPoints.traefik.address=:9000/tcp
      - --entryPoints.udpep.address=:18080/udp
      - --entryPoints.web.address=:8000/tcp
      - --entryPoints.websecure.address=:8443/tcp
      - --api.dashboard=true
      - --ping=true
      - --providers.kubernetescrd
      - --providers.kubernetesingress
    ......
    

UDP 的入口点增加成功后，接下来我们可以创建一个 `IngressRouteUDP` 类型的资源对象，用来代理 UDP 请求：
    
    
    ➜ cat <<EOF | kubectl apply -f -
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRouteUDP
    metadata:
      name: whoamiudp
    spec:
      entryPoints:
      - udpep
      routes:
      - services:
        - name: whoamiudp
          port: 8080
    EOF
    ➜ kubectl get ingressrouteudp
    NAME        AGE
    whoamiudp   31s
    

创建成功后我们首先在集群上通过 Service 来访问上面的 UDP 应用：
    
    
    ➜ kubectl get svc
    NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
    whoamiudp           ClusterIP   10.106.10.185    <none>        8080/UDP                                36m
    ➜ echo "WHO" | socat - udp4-datagram:10.106.10.185:8080
    Hostname: whoamiudp-d884bdb64-6mpk6
    IP: 127.0.0.1
    IP: 10.244.1.145
    ➜ echo "othermessage" | socat - udp4-datagram:10.106.10.185:8080
    Received: othermessage
    

我们这个应用当我们输入 `WHO` 的时候，就会打印出访问的 Pod 的 Hostname 这些信息，如果不是则打印接收到字符串。现在我们通过 Traefik 所在节点的 IP（10.151.30.11）与 18080 端口来访问 UDP 应用进行测试：
    
    
    ➜ echo "othermessage" | socat - udp4-datagram:10.151.30.11:18080
    Received: othermessage
    ➜  echo "WHO" | socat - udp4-datagram:10.151.30.11:18080
    Hostname: whoamiudp-d884bdb64-hkw6k
    IP: 127.0.0.1
    IP: 10.244.2.87
    

我们可以看到测试成功了，证明我就用 Traefik 来代理 UDP 应用成功了。除此之外 Traefik 还有很多功能，特别是强大的中间件和自定义插件的功能，为我们提供了不断扩展其功能的能力，我们完成可以根据自己的需求进行二次开发。

## 多控制器

有的业务场景下可能需要在一个集群中部署多个 traefik，不同的实例控制不同的 IngressRoute 资源对象，要实现该功能有两种方法：

第一种方法：通过 annotations 注解筛选:

  * 首先在 traefik 中增加启动参数 `--providers.kubernetescrd.ingressclass=traefik-in`
  * 然后在 IngressRoute 资源对象中添加 `kubernetes.io/ingress.class: traefik-in` 注解即可



第二种方法：通过标签选择器进行过滤：

  * 首先在 traefik 中增加启动参数 `--providers.kubernetescrd.labelselector=ingressclass=traefik-out`
  * 然后在 IngressRoute 资源对象中添加 `ingressclass: traefik-out` 这个标签即可


