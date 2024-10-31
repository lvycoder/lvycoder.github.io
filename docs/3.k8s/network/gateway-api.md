# Gateway API

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/network/gateway-api.md "编辑此页")

# Gateway API

`Gateway API`（之前叫 Service API）是由 [SIG-NETWORK 社区](https://github.com/kubernetes/community/tree/master/sig-network)管理的开源项目，项目地址：<https://gateway-api.sigs.k8s.io/>。主要原因是 Ingress 资源对象不能很好的满足网络需求，很多场景下 Ingress 控制器都需要通过定义 annotations 或者 crd 来进行功能扩展，这对于使用标准和支持是非常不利的，新推出的 Gateway API 旨在通过可扩展的面向角色的接口来增强服务网络。

Gateway API 是 Kubernetes 中的一个 API 资源集合，包括 GatewayClass、Gateway、HTTPRoute、TCPRoute、Service 等，这些资源共同为各种网络用例构建模型。

![Gateway API](https://picdn.youdianzhishi.com/images/20201231093733.png)

Gateway API 的改进比当前的 Ingress 资源对象有很多更好的设计：

  * 面向角色 - Gateway 由各种 API 资源组成，这些资源根据使用和配置 Kubernetes 服务网络的角色进行建模。
  * 通用性 - 和 Ingress 一样是一个具有众多实现的通用规范，Gateway API 是一个被设计成由许多实现支持的规范标准。
  * 更具表现力 - Gateway API 资源支持基于 Header 头的匹配、流量权重等核心功能，这些功能在 Ingress 中只能通过自定义注解才能实现。
  * 可扩展性 - Gateway API 允许自定义资源链接到 API 的各个层，这就允许在 API 结构的适当位置进行更精细的定制。



还有一些其他值得关注的功能：

  * GatewayClasses - `GatewayClasses` 将负载均衡实现的类型形式化，这些类使用户可以很容易了解到通过 Kubernetes 资源可以获得什么样的能力。
  * 共享网关和跨命名空间支持 - 它们允许共享负载均衡器和 VIP，允许独立的路由资源绑定到同一个网关，这使得团队可以安全地共享（包括跨命名空间）基础设施，而不需要直接协调。
  * 规范化路由和后端 - Gateway API 支持类型化的路由资源和不同类型的后端，这使得 API 可以灵活地支持各种协议（如 HTTP 和 gRPC）和各种后端服务（如 Kubernetes Service、存储桶或函数）。



## 面向角色设计

无论是道路、电力、数据中心还是 Kubernetes 集群，基础设施都是为了共享而建的，然而共享基础设施提供了一个共同的挑战，那就是如何为基础设施用户提供灵活性的同时还能被所有者控制。

Gateway API 通过对 Kubernetes 服务网络进行面向角色的设计来实现这一目标，平衡了灵活性和集中控制。它允许共享的网络基础设施（硬件负载均衡器、云网络、集群托管的代理等）被许多不同的团队使用，所有这些都受到集群运维设置的各种策略和约束。下面的例子显示了是如何在实践中运行的。

![gateway api demo](https://picdn.youdianzhishi.com/images/20220102164222.png)

一个集群运维人员创建了一个基于 GatewayClass 的 Gateway 资源，这个 Gateway 部署或配置了它所代表的基础网络资源，集群运维和特定的团队必须沟通什么可以附加到这个 Gateway 上来暴露他们的应用。 集中的策略，如 TLS，可以由集群运维在 Gateway 上强制执行，同时，Store 和 Site 应用在他们自己的命名空间中运行，但将他们的路由附加到相同的共享网关上，允许他们独立控制他们的路由逻辑。

这种关注点分离的设计可以使不同的团队能够管理他们自己的流量，同时将集中的策略和控制留给集群运维。

## 概念

在整个 Gateway API 中涉及到 3 个角色：基础设施提供商、集群管理员、应用开发人员，在某些场景下可能还会涉及到应用管理员等角色。Gateway API 中定义了 3 种主要的资源模型：`GatewayClass`、`Gateway`、`Route`。

### GatewayClass

`GatewayClass` 定义了一组共享相同配置和动作的网关。每个`GatewayClass` 由一个控制器处理，是一个集群范围的资源，必须至少有一个 `GatewayClass` 被定义。

这与 Ingress 的 IngressClass 类似，在 Ingress v1beta1 版本中，与 GatewayClass 类似的是 `ingress-class` 注解，而在 Ingress V1 版本中，最接近的就是 `IngressClass` 资源对象。

### Gateway

Gateway 网关描述了如何将流量转化为集群内的服务，也就是说，它定义了一个请求，要求将流量从不了解 Kubernetes 的地方转换到集群内的服务。例如，由云端负载均衡器、集群内代理或外部硬件负载均衡器发送到 Kubernetes 服务的流量。

它定义了对特定负载均衡器配置的请求，该配置实现了 GatewayClass 的配置和行为规范，该资源可以由管理员直接创建，也可以由处理 `GatewayClass` 的控制器创建。

Gateway 可以附加到一个或多个路由引用上，这些路由引用的作用是将流量的一个子集导向特定的服务。

### Route 资源

路由资源定义了特定的规则，用于将请求从网关映射到 Kubernetes 服务。

从 `v1alpha2` 版本开始，API 中包含四种 Route 路由资源类型，对于其他未定义的协议，鼓励采用特定实现的自定义路由类型，当然未来也可能会添加新的路由类型。

**HTTPRoute**

`HTTPRoute` 是用于 HTTP 或 HTTPS 连接，适用于我们想要检查 HTTP 请求并使用 HTTP 请求进行路由或修改的场景，比如使用 HTTP Headers 头进行路由，或在请求过程中对它们进行修改。

**TLSRoute**

TLSRoute 用于 TLS 连接，通过 SNI 进行区分，它适用于希望使用 SNI 作为主要路由方法的地方，并且对 HTTP 等更高级别协议的属性不感兴趣，连接的字节流不经任何检查就被代理到后端。

**TCPRoute 和 UDPRoute**

TCPRoute（和 UDPRoute）旨在用于将一个或多个端口映射到单个后端。在这种情况下，没有可以用来选择同一端口的不同后端的判别器，所以每个 TCPRoute 在监听器上需要一个不同的端口。你可以使用 TLS，在这种情况下，未加密的字节流会被传递到后端，当然也可以不使用 TLS，这样加密的字节流将传递到后端。

### 组合

`GatewayClass`、`Gateway`、`xRoute` 和 `Service` 的组合定义了一个可实施的负载均衡器。下图说明了不同资源之间的关系:

![组合关系](https://picdn.youdianzhishi.com/images/20220105152100.png)

使用反向代理实现的网关的典型客户端/网关 API 请求流程如下所示：

  *     1. 客户端向 `http://foo.example.com` 发出请求
  *     1. DNS 将域名解析为 `Gateway` 网关地址
  *     1. 反向代理在监听器上接收请求，并使用 Host Header 来匹配 HTTPRoute
  *     1. (可选)反向代理可以根据 HTTPRoute 的匹配规则进行路由
  *     1. (可选)反向代理可以根据 HTTPRoute 的过滤规则修改请求，即添加或删除 headers
  *     1. 最后，反向代理根据 HTTPRoute 的 `forwardTo` 规则，将请求转发给集群中的一个或多个对象，即服务。



## 实现

目前已经有很多 Gateway API 的控制器实现方案了，比如 Contour、Google Kubernetes Engine、Istio、Traefik 等等。接下来我们以 Traefik 为例来进行测试。不过需要注意的是 Traefik 目前是基于 `v1alpha1` 规范实现的，可能和上面提到的一些概念略有不同。

要在 Traefik 中使用 Gateway API，首先我们需要先手动安装 Gateway API 的 CRDs，使用如下命令即可安装，这将安装包括 GatewayClass、Gateway、HTTPRoute、TCPRoute 等 CRDs：
    
    
    ➜ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" \
    | kubectl apply -f -
    

然后我们需要在 Traefik 中开启 `kubernetesgateway` 这个 Provider，同样基于前面 Traefik 章节中的 Helm Chart 包进行定义，设置 `experimental.kubernetesGateway.enabled=true`，完整的 Values 文件如下所示：
    
    
    # ci/deployment-prod.yaml
    
    # Enable experimental features
    experimental:
      kubernetesGateway: # 开启 gateway api 支持
        enabled: true
    
    providers:
      kubernetesCRD:
        enabled: true
        allowCrossNamespace: true # 是否允许跨命名空间
        allowExternalNameServices: true # 是否允许使用 ExternalName 的服务
    
      kubernetesIngress:
        enabled: true
        allowExternalNameServices: true
    # ......
    # 其他忽略
    

然后使用下面的命令更新 Traefik 即可：
    
    
    ➜ helm upgrade --install traefik ./traefik -f ./traefik/ci/deployment-prod.yaml --namespace kube-system
    

更新完成后可以前往 Traefik 的 Dashboard 查看是否已经启用 `KubernetesGateway` 这个 Provider：

![KubernetesGateway Provider](https://picdn.youdianzhishi.com/images/20220105154405.png)

正常情况下启用成功后 Traefik 也会创建一个默认的 `GatewayClass` 资源对象和 `Gateway` 实例：
    
    
    ➜ kubectl get gatewayclass
    NAME      CONTROLLER                      AGE
    traefik   traefik.io/gateway-controller   4m13s
    ➜ kubectl get gatewayclass traefik -o yaml
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: GatewayClass
    metadata:
      name: traefik
    spec:
      controller: traefik.io/gateway-controller
    ......
    ➜ kubectl get gateway -n kube-system
    NAME              CLASS     AGE
    traefik-gateway   traefik   5m55s
    ➜ kubectl get gateway -n kube-system traefik-gateway -o yaml
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: Gateway
    metadata:
      name: traefik-gateway
      namespace: kube-system
    spec:
      gatewayClassName: traefik
      listeners:
      - port: 8000
        protocol: HTTP
        routes:
          group: networking.x-k8s.io
          kind: HTTPRoute
          namespaces:
            from: Same
          selector:
            matchLabels:
              app: traefik
    ......
    

可以看到默认创建的 `Gateway` 实例引用了 `traefik` 这个 `GatewayClass`，其中 `listeners` 部分定义了该网关关联的监听器入口，监听器定义逻辑端点绑定在该网关地址上，至少需要指定一个监听器，下面的 `HTTPRoute` 定义了路由规则，`namespaces` 表示应该在哪些命名空间中为该网关选择路由，默认情况下，这被限制在该网关的命名空间中，`Selector` 则指定一组路由标签，如果定义了这个 Selector，则只路由匹配选择器与网关相关联的对象，一个空的选择器匹配所有对象，这里会去匹配具有 `app: traefik` 标签的对象。

> 为了能够处理其他命名空间中的路由规则，我们可以将这里的 `namespaces.from` 修改为 `All`，但是经测试未生效？

下面我们安装一个简单的 `whoami` 服务来进行测试，直接使用下面的资源清单部署对应的服务即可：
    
    
    # 01-whoami.yaml
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: whoami
      namespace: kube-system
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
                - containerPort: 80
                  name: http
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: whoami
      namespace: kube-system
    spec:
      ports:
        - protocol: TCP
          port: 80
          targetPort: http
      selector:
        app: whoami
    

测试服务部署完成后，我们就可以使用 Gateway API 的方式来进行流量配置了。

### 部署一个简单的 Host 主机

在以前的方式中我们会创建一个 Ingress 或 IngressRoute 资源对象，这里我们将部署一个简单的 `HTTPRoute` 对象。
    
    
    # 02-whoami-httproute.yaml
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: HTTPRoute
    metadata:
      name: http-app-1
      namespace: kube-system
      labels:
        app: traefik
    spec:
      hostnames:
        - "whoami"
      rules:
        - matches:
            - path:
                type: Exact
                value: /
          forwardTo:
            - serviceName: whoami
              port: 80
              weight: 1
    

上面的 HTTPRoute 资源会捕捉到向 whoami 主机名发出的请求，并将其转发到上面部署的 whoami 服务，如果你现在对这个主机名进行请求，你会看到典型的 whoami 输出：
    
    
    ➜ kubectl apply -f 02-whoami-httproute.yaml
    ➜ kubectl get httproute -n kube-system
    NAME         HOSTNAMES    AGE
    http-app-1   ["whoami"]   25s
    # 使用 whoami 这个主机名进行访问测试
    ➜ curl -H "Host: whoami" http://192.168.31.108
    Hostname: whoami-6b465b89d6-lcg4k
    IP: 127.0.0.1
    IP: ::1
    IP: 10.244.1.87
    IP: fe80::cccc:6aff:fef8:eca9
    RemoteAddr: 10.244.1.85:60384
    GET / HTTP/1.1
    Host: whoami
    User-Agent: curl/7.64.1
    Accept: */*
    Accept-Encoding: gzip
    X-Forwarded-For: 192.168.31.9
    X-Forwarded-Host: whoami
    X-Forwarded-Port: 80
    X-Forwarded-Proto: http
    X-Forwarded-Server: traefik-84d4cccf9c-2pl5r
    X-Real-Ip: 192.168.31.9
    

另外需要注意上面 HTTPRoute 对象中需要定义 `app：traefik` 标签，否则创建的 `Gateway` 实例不能关联上。

### 带路径的 Host 主机

上面的例子可以很容易地限制流量只在一个给定的子路径上进行路由。
    
    
    # 03-whoami-httproute-paths.yaml
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: HTTPRoute
    metadata:
      name: http-app-1
      namespace: kube-system
      labels:
        app: traefik
    spec:
      hostnames:
        - whoami
      rules:
        - forwardTo:
            - port: 80
              serviceName: whoami
              weight: 1
          matches:
            - path:
                type: Exact # 匹配 /foo 的路径
                value: /foo
    

创建上面修改后的 HTTPRoute，你会发现之前的请求现在返回 404 错误，而请求 /foo 路径后缀则返回成功。
    
    
    ➜ curl -H "Host: whoami" http://192.168.31.108
    404 page not found
    ➜ curl -H "Host: whoami" http://192.168.31.108/foo
    Hostname: whoami-6b465b89d6-p5vwz
    IP: 127.0.0.1
    IP: ::1
    IP: 10.244.2.154
    IP: fe80::7045:53ff:fef9:fadc
    RemoteAddr: 10.244.1.85:51686
    GET /foo HTTP/1.1
    Host: whoami
    User-Agent: curl/7.64.1
    Accept: */*
    Accept-Encoding: gzip
    X-Forwarded-For: 192.168.31.9
    X-Forwarded-Host: whoami
    X-Forwarded-Port: 80
    X-Forwarded-Proto: http
    X-Forwarded-Server: traefik-84d4cccf9c-2pl5r
    X-Real-Ip: 192.168.31.9
    

关于请求的哪些部分可以被匹配的更多信息可以在官方 Gateway APIs 文档（https://gateway-api.sigs.k8s.io/v1alpha1/api-types/httproute/#rules）中找到。

### 金丝雀发布

Gateway APIs 规范可以支持的另一个功能是金丝雀发布，假设你想在一个端点上运行两个不同的服务（或同一服务的两个版本），并将一部分请求路由到每个端点，则可以通过修改你的 HTTPRoute 来实现。

首先，我们需要运行第二个服务，这里我们快速生成一个 Nginx 的实例来进行测试。
    
    
    # 03-nginx.yaml
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: nginx
      namespace: kube-system
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
            - name: nginx
              image: nginx
              ports:
                - containerPort: 80
                  name: http
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      namespace: kube-system
    spec:
      ports:
        - protocol: TCP
          port: 80
          targetPort: http
      selector:
        app: nginx
    

接着我们修改前面的 HTTPRoute 资源对象，其中有一个 weight 选项，可以为两个服务分别分配不同的权重，如下所示：
    
    
    # 04-whoami-nginx-canary.yaml
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: HTTPRoute
    metadata:
      labels:
        app: traefik
      name: http-app-1
      namespace: kube-system
    spec:
      hostnames:
        - whoami
      rules:
        - forwardTo:
            - port: 80
              serviceName: whoami
              weight: 3 # 3/4 的请求到whoami
            - port: 80
              serviceName: nginx
              weight: 1 # 1/4 的请求到whoami
    

创建上面的 HTTPRoute 后，现在我们可以再次访问 whoami 服务，正常我们可以看到有大约 25%的请求会看到 Nginx 的响应，而不是 whoami 的响应。

到这里我们就使用 Traefik 来测试了 Kubernetes Gateway APIs 的使用。目前，Traefik 对 Gateway APIs 的实现是基于 `v1alpha1` 版本的规范，目前最新的规范是 `v1alpha2`，所以和最新的规范可能有一些出入的地方。
