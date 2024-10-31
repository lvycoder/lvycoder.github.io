# Ingress

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/network/ingress.md "编辑此页")

# Ingress

对外暴露集群服务

前面我们学习了在 Kubernetes 集群内部使用 kube-dns 实现服务发现的功能，那么我们部署在 Kubernetes 集群中的应用如何暴露给外部的用户使用呢？我们知道可以使用 `NodePort` 和 `LoadBlancer` 类型的 Service 可以把应用暴露给外部用户使用，除此之外，Kubernetes 还为我们提供了一个非常重要的资源对象可以用来暴露服务给外部用户，那就是 `Ingress`。对于小规模的应用我们使用 NodePort 或许能够满足我们的需求，但是当你的应用越来越多的时候，你就会发现对于 NodePort 的管理就非常麻烦了，这个时候使用 Ingress 就非常方便了，可以避免管理大量的端口。

## 资源对象

`Ingress` 资源对象是 Kubernetes 内置定义的一个对象，是从 Kuberenets 集群外部访问集群的一个入口，将外部的请求转发到集群内不同的 Service 上，其实就相当于 nginx、haproxy 等负载均衡代理服务器，可能你会觉得我们直接使用 nginx 就实现了，但是只使用 nginx 这种方式有很大缺陷，每次有新服务加入的时候怎么改 Nginx 配置？不可能让我们去手动更改或者滚动更新前端的 Nginx Pod 吧？那我们再加上一个服务发现的工具比如 consul 如何？貌似是可以，对吧？Ingress 实际上就是这样实现的，只是服务发现的功能自己实现了，不需要使用第三方的服务了，然后再加上一个域名规则定义，路由信息的刷新依靠 Ingress Controller 来提供。

![ingress flow](https://picdn.youdianzhishi.com/images/ingress-flow.png)

Ingress Controller 可以理解为一个监听器，通过不断地监听 kube-apiserver，实时的感知后端 Service、Pod 的变化，当得到这些信息变化后，Ingress Controller 再结合 Ingress 的配置，更新反向代理负载均衡器，达到服务发现的作用。其实这点和服务发现工具 consul、 consul-template 非常类似。

## 定义

一个常见的 Ingress 资源清单如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: demo-ingress
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
      rules:
        - http:
            paths:
              - path: /testpath
                pathType: Prefix
                backend:
                  service:
                    name: test
                    port:
                      number: 80
    

上面这个 Ingress 资源的定义，配置了一个路径为 `/testpath` 的路由，所有 `/testpath/**` 的入站请求，会被 Ingress 转发至名为 test 的服务的 80 端口的 `/` 路径下。可以将 Ingress 狭义的理解为 Nginx 中的配置文件 `nginx.conf`。

此外 Ingress 经常使用注解 `annotations` 来配置一些选项，当然这具体取决于 Ingress 控制器的实现方式，不同的 Ingress 控制器支持不同的注解。

另外需要注意的是当前集群版本是 `v1.22`，这里使用的 apiVersion 是 `networking.k8s.io/v1`，所以如果是之前版本的 Ingress 资源对象需要进行迁移。 Ingress 资源清单的描述我们可以使用 `kubectl explain` 命令来了解：
    
    
    ➜ kubectl explain ingress.spec
    KIND:     Ingress
    VERSION:  networking.k8s.io/v1
    
    RESOURCE: spec <Object>
    
    DESCRIPTION:
         Spec is the desired state of the Ingress. More info:
         https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status
    
         IngressSpec describes the Ingress the user wishes to exist.
    
    FIELDS:
       defaultBackend       <Object>
         DefaultBackend is the backend that should handle requests that don't match
         any rule. If Rules are not specified, DefaultBackend must be specified. If
         DefaultBackend is not set, the handling of requests that do not match any
         of the rules will be up to the Ingress controller.
    
       ingressClassName     <string>
         IngressClassName is the name of the IngressClass cluster resource. The
         associated IngressClass defines which controller will implement the
         resource. This replaces the deprecated `kubernetes.io/ingress.class`
         annotation. For backwards compatibility, when that annotation is set, it
         must be given precedence over this field. The controller may emit a warning
         if the field and annotation have different values. Implementations of this
         API should ignore Ingresses without a class specified. An IngressClass
         resource may be marked as default, which can be used to set a default value
         for this field. For more information, refer to the IngressClass
         documentation.
    
       rules        <[]Object>
         A list of host rules used to configure the Ingress. If unspecified, or no
         rule matches, all traffic is sent to the default backend.
    
       tls  <[]Object>
         TLS configuration. Currently the Ingress only supports a single TLS port,
         443. If multiple members of this list specify different hosts, they will be
         multiplexed on the same port according to the hostname specified through
         the SNI TLS extension, if the ingress controller fulfilling the ingress
         supports SNI.
    

从上面描述可以看出 Ingress 资源对象中有几个重要的属性：`defaultBackend`、`ingressClassName`、`rules`、`tls`。

### rules

其中核心部分是 `rules` 属性的配置，每个路由规则都在下面进行配置：

  * `host`：可选字段，上面我们没有指定 host 属性，所以该规则适用于通过指定 IP 地址的所有入站 HTTP 通信，如果提供了 host 域名，则 `rules` 则会匹配该域名的相关请求，此外 `host` 主机名可以是精确匹配（例如 `foo.bar.com`）或者使用通配符来匹配（例如 `*.foo.com`）。
  * `http.paths`：定义访问的路径列表，比如上面定义的 `/testpath`，每个路径都有一个由 `backend.service.name` 和 `backend.service.port.number` 定义关联的 Service 后端，在控制器将流量路由到引用的服务之前，`host` 和 `path` 都必须匹配传入的请求才行。
  * `backend`：该字段其实就是用来定义后端的 Service 服务的，与路由规则中 `host` 和 `path` 匹配的流量会将发送到对应的 backend 后端去。



> 此外一般情况下在 Ingress 控制器中会配置一个 `defaultBackend` 默认后端，当请求不匹配任何 Ingress 中的路由规则的时候会使用该后端。`defaultBackend` 通常是 Ingress 控制器的配置选项，而非在 Ingress 资源中指定。

### Resource

`backend` 后端除了可以引用一个 Service 服务之外，还可以通过一个 `resource` 资源进行关联，`Resource` 是当前 Ingress 对象命名空间下引用的另外一个 Kubernetes 资源对象，但是需要注意的是 `Resource` 与 `Service` 配置是互斥的，只能配置一个，`Resource` 后端的一种常见用法是将所有入站数据导向带有静态资产的对象存储后端，如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: ingress-resource-backend
    spec:
      rules:
        - http:
            paths:
              - path: /icons
                pathType: ImplementationSpecific
                backend:
                  resource:
                    apiGroup: k8s.example.com
                    kind: StorageBucket
                    name: icon-assets
    

该 Ingress 资源对象描述了所有的 `/icons` 请求会被路由到同命名空间下的名为 `icon-assets` 的 `StorageBucket` 资源中去进行处理。

### pathType

上面的示例中在定义路径规则的时候都指定了一个 `pathType` 的字段，事实上每个路径都需要有对应的路径类型，当前支持的路径类型有三种：

  * `ImplementationSpecific`：该路径类型的匹配方法取决于 `IngressClass`，具体实现可以将其作为单独的 pathType 处理或者与 `Prefix` 或 `Exact` 类型作相同处理。
  * `Exact`：精确匹配 URL 路径，且区分大小写。
  * `Prefix`：基于以 `/` 分隔的 URL 路径前缀匹配，匹配区分大小写，并且对路径中的元素逐个完成，路径元素指的是由 `/` 分隔符分隔的路径中的标签列表。



`Exact` 比较简单，就是需要精确匹配 URL 路径，对于 `Prefix` 前缀匹配，需要注意如果路径的最后一个元素是请求路径中最后一个元素的子字符串，则不会匹配，例如 `/foo/bar` 可以匹配 `/foo/bar/baz`, 但不匹配 `/foo/barbaz`，可以查看下表了解更多的匹配场景（来自官网）：

![示例](https://picdn.youdianzhishi.com/images/20211214171445.png)

> 在某些情况下，Ingress 中的多条路径会匹配同一个请求，这种情况下最长的匹配路径优先，如果仍然有两条同等的匹配路径，则精确路径类型优先于前缀路径类型。

### IngressClass

Kubernetes 1.18 起，正式提供了一个 `IngressClass` 资源，作用与 `kubernetes.io/ingress.class` 注解类似，因为可能在集群中有多个 Ingress 控制器，可以通过该对象来定义我们的控制器，例如：
    
    
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: external-lb
    spec:
      controller: nginx-ingress-internal-controller
      parameters:
        apiGroup: k8s.example.com
        kind: IngressParameters
        name: external-lb
    

其中重要的属性是 `metadata.name` 和 `spec.controller`，前者是这个 `IngressClass` 的名称，需要设置在 Ingress 中，后者是 Ingress 控制器的名称。

Ingress 中的 `spec.ingressClassName` 属性就可以用来指定对应的 IngressClass，并进而由 IngressClass 关联到对应的 Ingress 控制器，如：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: myapp
    spec:
      ingressClassName: external-lb # 上面定义的 IngressClass 对象名称
      defaultBackend:
        service:
          name: myapp
          port:
            number: 80
    

不过需要注意的是 `spec.ingressClassName` 与老版本的 `kubernetes.io/ingress.class` 注解的作用并不完全相同，因为 `ingressClassName` 字段引用的是 `IngressClass` 资源的名称，`IngressClass` 资源中除了指定了 Ingress 控制器的名称之外，还可能会通过 `spec.parameters` 属性定义一些额外的配置。

比如 `parameters` 字段有一个 `scope` 和 `namespace` 字段，可用来引用特定于命名空间的资源，对 Ingress 类进行配置。 `scope` 字段默认为 `Cluster`，表示默认是集群作用域的资源。将 `scope` 设置为 `Namespace` 并设置 `namespace` 字段就可以引用某特定命名空间中的参数资源，比如：
    
    
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: external-lb
    spec:
      controller: nginx-ingress-internal-controller
      parameters:
        apiGroup: k8s.example.com
        kind: IngressParameters
        name: external-lb
        namespace: external-configuration
        scope: Namespace
    

由于一个集群中可能有多个 Ingress 控制器，所以我们还可以将一个特定的 `IngressClass` 对象标记为集群默认是 Ingress 类。只需要将一个 IngressClass 资源的 `ingressclass.kubernetes.io/is-default-class` 注解设置为 true 即可，这样未指定 `ingressClassName` 字段的 Ingress 就会使用这个默认的 IngressClass。

> 如果集群中有多个 `IngressClass` 被标记为默认，准入控制器将阻止创建新的未指定 `ingressClassName` 的 Ingress 对象。最好的方式还是确保集群中最多只能有一个 `IngressClass` 被标记为默认。

### TLS

Ingress 资源对象还可以用来配置 Https 的服务，可以通过设定包含 TLS 私钥和证书的 Secret 来保护 Ingress。 Ingress 只支持单个 TLS 端口 443，如果 Ingress 中的 TLS 配置部分指定了不同的主机，那么它们将根据通过 SNI TLS 扩展指定的主机名 （如果 Ingress 控制器支持 SNI）在同一端口上进行复用。需要注意 TLS Secret 必须包含名为 `tls.crt` 和 `tls.key` 的键名，例如：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: testsecret-tls
      namespace: default
    data:
      tls.crt: base64 编码的 cert
      tls.key: base64 编码的 key
    type: kubernetes.io/tls
    

在 Ingress 中引用此 Secret 将会告诉 Ingress 控制器使用 TLS 加密从客户端到负载均衡器的通道，我们需要确保创建的 TLS Secret 创建自包含 `https-example.foo.com` 的公用名称的证书，如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: tls-example-ingress
    spec:
      tls:
        - hosts:
            - https-example.foo.com
          secretName: testsecret-tls
      rules:
        - host: https-example.foo.com
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: service1
                    port:
                      number: 80
    

现在我们了解了如何定义 Ingress 资源对象了，但是仅创建 Ingress 资源本身没有任何效果。还需要部署 Ingress 控制器，例如 `ingress-nginx`，现在可以供大家使用的 Ingress 控制器有很多，比如 traefik、nginx-controller、Kubernetes Ingress Controller for Kong、HAProxy Ingress controller，当然你也可以自己实现一个 Ingress Controller，现在普遍用得较多的是 traefik 和 ingress-nginx，traefik 的性能比 ingress-nginx 差，但是配置使用要简单许多，我们这里会重点给大家介绍 ingress-nginx、traefik 以及 apisix 的使用。

> 实际上社区目前还在开发一组高配置能力的 API，被称为 [Service API](https://gateway-api.sigs.k8s.io/)，新 API 会提供一种 Ingress 的替代方案，它的存在目的不是替代 Ingress，而是提供一种更具配置能力的新方案。
