# Ingress 流量

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/linkerd/ingress.md "编辑此页")

# Ingress 流量

出于简单，Linkerd 本身并没有提供内置的 Ingress 控制器，Linkerd 旨在与现有的 Kubernetes Ingress 解决方案一起使用。

要结合 Linkerd 和你的 Ingress 解决方案需要两件事：

  * 配置你的 Ingress 以支持 Linkerd。
  * 网格化你的 Ingress 控制器，以便它们安装 Linkerd 代理。



对 Ingress 控制器进行网格化将允许 Linkerd 在流量进入集群时提供 L7 指标和 mTLS 等功能，Linkerd 支持与大部分 Ingress 控制器进行集成，包括：

  * Ambassador
  * Nginx
  * Traefik
  * Traefik 1.x
  * Traefik 2.x
  * GCE
  * Gloo
  * Contour
  * Kong
  * Haproxy



## ingress-nginx

我们这里以集群中使用的 ingress-nginx 为例来说明如何将其与 Linkerd 进行集成使用。
    
    
    $ kubectl get deploy -n ingress-nginx
    NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
    ingress-nginx-controller       1/1     1            1           57d
    ingress-nginx-defaultbackend   1/1     1            1           57d
    $ kubectl get pods -n ingress-nginx
    NAME                                            READY   STATUS     RESTARTS       AGE
    ingress-nginx-controller-7647c44fb9-sss9m       1/1     Running    26 (59m ago)   57d
    ingress-nginx-defaultbackend-84854cd6cb-rvgd2   1/1     Running    27 (59m ago)   57d
    

首先我们需要更新 `ingress-nginx-controller` 控制器，为 Pod 添加一个 `linkerd.io/inject: enabled` 注解，可以直接 `kubectl edit` 这个 Deployment，由于我们集群中的 ingress-nginx 使用的 Helm Chart 安装的，所以可以在 values 中添加如下所示的配置：
    
    
    controller:
      podAnnotations:
        linkerd.io/inject: enabled
    # ......
    

然后使用该 values 重新更新即可：
    
    
    # Update your helm repos with the ingress-nginx repo
    $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    $ helm repo update
    
    # Install the ingress-nginx chart
    $ helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace=ingress-nginx --values=values.yaml
    

更新后 ingress-nginx 的控制器 Pod 就会被自动注入一个 linkerd proxy 的 sidecar 容器：
    
    
    $ kubectl get pods -n ingress-nginx
    NAME                                            READY   STATUS    RESTARTS       AGE
    ingress-nginx-controller-f56c7f6fd-rxhrs        2/2     Running   0              4m21s
    ingress-nginx-defaultbackend-84854cd6cb-rvgd2   1/1     Running   27 (62m ago)   57d
    

这样 ingress 控制器也被加入到网格中去了，所以也具有了 Linkerd 网格的相关功能：

  * 为 Ingress 控制器提供黄金指标（每秒请求数等）。
  * Ingress 控制器 Pod 和网格应用 Pod 之间的流量是加密的（并相互验证）。
  * 可以看到 HTTP 流量
  * 当应用程序返回错误（如 5xx HTTP 状态代码）时，这将在 Linkerd UI 中看到，不仅是应用程序，还有 nginx ingress 控制器，因为它向客户端返回错误代码。



在 Linkerd Dashboard 中也可以看到对应的指标数据了。

![ingress-nginx metrics](https://picdn.youdianzhishi.com/images/1662453508527.png)

对应在 Grafana 中也可以看到对应的图表信息。

![ingress-nginx grafana](https://picdn.youdianzhishi.com/images/1662453547119.png)

接下来我们为 `Emojivoto` 应用添加一个对应的 Ingress 资源对象来对外暴露服务。
    
    
    # emojivoto-ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: emojivoto-ingress
      labels:
        name: emojivoto-ingress
      namespace: emojivoto
      annotations:
        # add below line of nginx is meshed
        nginx.ingress.kubernetes.io/service-upstream: "true"
        # nginx.ingress.kubernetes.io/affinity: "cookie"
        # nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    spec:
      ingressClassName: nginx
      rules:
        # update IP with your own IP used by Ingress Controller
        - host: emoji.192.168.0.52.nip.io
          http:
            paths:
              - pathType: Prefix
                path: /
                backend:
                  service:
                    name: web-svc-2
                    port:
                      number: 80
    

直接应用上面的资源对象即可：
    
    
    $ kubectl apply -f emojivoto-ingress.yaml
    $ kubectl get ingress -n emojivoto
    NAME                CLASS   HOSTS                       ADDRESS        PORTS   AGE
    emojivoto-ingress   nginx   emoji.192.168.0.52.nip.io   192.168.0.52   80      61s
    

其中 `nip.io` 是任何 IP 地址的简单通配符 DNS，这样我们就不用使用自定义主机名和 IP 地址映射来编辑你的 `etc/hosts` 文件了，`nip.io` 允许你通过使用以下格式将任何 IP 地址映射到一个主机名。

**不带名称**

  * 10.0.0.1.nip.io 映射到 10.0.0.1
  * 192-168-1-250.nip.io 映射到 192.168.1.250
  * 0a000803.nip.io 映射到 10.0.8.3



**带名称**

  * app.10.8.0.1.nip.io 映射到 10.8.0.1
  * app-116-203-255-68.nip.io 映射到 116.203.255.68
  * app-c0a801fc.nip.io 映射到 192.168.1.252
  * customer1.app.10.0.0.1.nip.io 映射到 10.0.0.1
  * customer2-app-127-0-0-1.nip.io 映射到 127.0.0.1
  * customer3-app-7f000101.nip.io 映射到 127.0.1.1



`nip.io` 将 `<anything>[.-]<IP Address>.nip.io` 以`"点"`、`"破折号"`或`"十六进制"`符号映射到相应的 `<IP Address>`。

我们这里使用一个自定义的域名 `emoji.192.168.0.52.nip.io` 相当于直接映射到 `192.168.0.52` 这个 IP 地址上，该地址是我们 ingress-nginx 的入口地址，这样我们不需要做任何映射即可访问服务了。

![emojivoto](https://picdn.youdianzhishi.com/images/1662454740334.png)

另外需要注意在上面的 Ingress 中我们添加了一个 `nginx.ingress.kubernetes.io/service-upstream: true` 的注解，这是用来告诉 Nginx Ingress Controller 将流量路由到网格应用的服务，而不是直接路由到 Pod。默认情况下，Ingress 控制器只是查询其目标服务的端点，以检索该服务背后的 Pod 的 IP 地址。而通过向网格服务发送流量，Linkerd 的相关功能如负载均衡和流量拆分则会被启用。

![ingress-nginx meshed](https://picdn.youdianzhishi.com/images/1662455942591.jpg)

## 限制对服务的访问

Linkerd policy 资源可用于限制哪些客户端可以访问服务。同样我们还是使用 `Emojivoto` 应用来展示如何限制对 `Voting` 微服务的访问，使其只能从 Web 服务中调用。

我们首先为 `Voting` 服务创建一个 `Server` 资源，`Server` 是 Linkerd 的另外一个 CRD 自定义资源，它用于描述工作负载的特定端口。一旦 `Server` 资源被创建，只有被授权的客户端才能访问它。

创建一个如下所示的资源对象：
    
    
    # voting-server.yaml
    apiVersion: policy.linkerd.io/v1beta1
    kind: Server
    metadata:
      name: voting-grpc
      namespace: emojivoto
      labels:
        app: voting-svc
    spec:
      podSelector:
        matchLabels:
          app: voting-svc
      port: grpc
      proxyProtocol: gRPC
    

直接应用上面的资源对象即可：
    
    
    $ kubectl apply -f voting-server.yaml
    server.policy.linkerd.io/voting-grpc created
    $ kubectl get server -n emojivoto
    NAME          PORT   PROTOCOL
    voting-grpc   grpc   gRPC
    

我们可以看到该 `Server` 使用了一个 `podSelector` 属性来选择它所描述的 Voting 服务的 Pod，它还指定了它适用的命名端口 (grpc)，最后指定在此端口上提供服务的协议为 `gRPC`， 这可确保代理正确处理流量并允许它跳过协议检测。

现在没有客户端被授权访问此服务，正常会看到成功率有所下降， 因为从 Web 服务到 Voting 的请求开始被拒绝，也可以直接查看 Web 服务的 Pod 日志来验证：
    
    
    $ kubectl logs -f web-svc-2-f9d77474f-vxlrh -n emojivoto -c web-svc-2
    2022/09/06 09:31:27 Error serving request [&{GET /api/vote?choice=:trophy: HTTP/1.1 1 1 map[Accept-Encoding:[gzip] L5d-Client-Id:[default.emojivoto.serviceaccount.identity.linkerd.cluster.local] L5d-Dst-Canonical:[web-apex.emojivoto.svc.cluster.local:80] User-Agent:[Go-http-client/1.1] X-B3-Sampled:[1] X-B3-Spanid:[f9e1dc6e24803ea8] X-B3-Traceid:[5ae662deee8fdbf2f3b9eaa40eb673d5]] {} <nil> 0 [] false web-apex.emojivoto:80 map[choice:[:trophy:]] map[] <nil> map[] 10.244.1.87:51244 /api/vote?choice=:trophy: <nil> <nil> <nil> 0xc00045e4b0}]: rpc error: code = PermissionDenied desc = unauthorized connection on server voting-grpc
    # ......
    

我们可以使用 `linkerd viz authz` 命令查看进入 Voting 服务的请求的授权状态：
    
    
    $ linkerd viz authz -n emojivoto deploy/voting
    SERVER       AUTHZ           SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
    voting-grpc  [UNAUTHORIZED]        -  0.9rps
    

可以看到所有传入的请求当前都处于未经授权状态。

接下来我们需要为客户端来授予访问该 Server 的权限，这里需要使用到另外一个 CRD 对象 `ServerAuthorization`，创建该对象来授予 Web 服务访问我们上面创建的 Voting Server 的权限，对应的资源清单文件如下所示：
    
    
    # voting-server-auth.yaml
    apiVersion: policy.linkerd.io/v1beta1
    kind: ServerAuthorization
    metadata:
      name: voting-grpc
      namespace: emojivoto
    spec:
      server:
        name: voting-grpc # 关联 Server 对象
      # The voting service only allows requests from the web service.
      client:
        meshTLS:
          serviceAccounts:
            - name: web
            - name: web-2
    

上面对象中通过 `spec.server.name` 来关联上面的 Server 对象，由于 meshTLS 使用 ServiceAccounts 作为身份基础，因此我们的授权也将基于 ServiceAccounts，所以通过 `spec.client.meshTLS.serviceAccounts` 来指定允许从哪些服务来访问 Voting 服务。

同样直接应用该资源清单即可：
    
    
    $ kubectl apply -f voting-server-auth.yaml
    serverauthorization.policy.linkerd.io/voting-grpc created
    $ kubectl get serverauthorization -n emojivoto
    NAME          SERVER
    voting-grpc   voting-grpc
    

有了这个对象后，我们现在可以看到所有对 Voting 服务的请求都是由 `voting-grpc` 这个 `ServerAuthorization` 授权的。请注意，由于 `linkerd viz auth` 命令在一个时间窗口内查询，所以可能会看到一些未授权(UNAUTHORIZED)的请求在短时间内显示。
    
    
    $ linkerd viz authz -n emojivoto deploy/voting
    SERVER       AUTHZ        SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
    voting-grpc  voting-grpc   84.48%  1.0rps          1ms          1ms          1ms
    

我们还可以通过创建一个 gRPC 客户端 Pod 来尝试从中访问 Voting 服务测试来自其他 Pod 的请求是否会被拒绝：
    
    
    $ kubectl run grpcurl --rm -it --image=networld/grpcurl --restart=Never --command -- ./grpcurl -plaintext voting-svc.emojivoto:8080 emojivoto.v1.VotingService/VoteDog
    If you don't see a command prompt, try pressing enter.
    Error attaching, falling back to logs: unable to upgrade connection: container grpcurl not found in pod grpcurl_default
    Error invoking method "emojivoto.v1.VotingService/VoteDog": failed to query for service descriptor "emojivoto.v1.VotingService": rpc error: code = PermissionDenied desc =
    pod "grpcurl" deleted
    pod default/grpcurl terminated (Error)
    

由于该 client 未经授权，所以该请求将被拒绝并显示 `PermissionDenied` 错误。

我们可以根据需要创建任意数量的 `ServerAuthorization` 资源来授权许多不同的客户端，还可以指定是授权未经身份验证（即 unmeshed）的客户端、任何经过身份验证的客户端，还是仅授权具有特定身份的经过身份验证的客户端。

此外我们还可以为整个集群设置一个默认策略，该策略将应用于所有未定义 Server 资源的。Linkerd 在决定是否允许请求时会使用以下逻辑：

  * 如果有一个 Server 资源并且客户端为其匹配一个 `ServerAuthorization` 资源，则为 `ALLOW`
  * 如果有一个 Server 资源，但客户端不匹配它的任何 `ServerAuthorizations`，则为 `DENY`
  * 如果端口没有 Server 资源，则使用默认策略



比如我们可以使用 `linkerd upgrade` 命令将默认策略设置为 `deny`：
    
    
    $ linkerd upgrade --set policyController.defaultAllowPolicy=deny | kubectl apply -f -
    

另外我们也可以通过设置 `config.linkerd.io/default-inbound-policy` 注解，可以在单个工作负载或命名空间上设置默认策略。

意思就是除非通过创建 `Server` 和 `ServerAuthorization` 对象明确授权，否则所有请求都将被拒绝，这样的话对于 `liveness` 和 `readiness` 探针需要明确授权，否则 Kubernetes 将无法将 Pod 识别为 live 或 ready 状态，并将重新启动它们。我们可以创建如下所示的策略对象，来允许所有客户端访问 Linkerd admin 端口，以便 Kubernetes 可以执行 `liveness` 和 `readiness` 检查：
    
    
    $ cat << EOF | kubectl apply -f -
    ---
    # Server "admin": matches the admin port for every pod in this namespace
    apiVersion: policy.linkerd.io/v1beta1
    kind: Server
    metadata:
      namespace: emojivoto
      name: admin
    spec:
      port: linkerd-admin
      podSelector:
        matchLabels: {} # every pod
      proxyProtocol: HTTP/1
    ---
    # ServerAuthorization "admin-everyone": allows unauthenticated access to the
    # "admin" Server, so that Kubernetes health checks can get through.
    apiVersion: policy.linkerd.io/v1beta1
    kind: ServerAuthorization
    metadata:
      namespace: emojivoto
      name: admin-everyone
    spec:
      server:
        name: admin
      client:
        unauthenticated: true
    

如果你知道 Kubelet（执行健康检查）的 IP 地址或范围， 也可以进一步将 `ServerAuthorization` 限制为这些 IP 地址或范围，比如如果你知道 Kubelet 在 `10.244.0.1` 上运行，那么你的 `ServerAuthorization` 可以改为：
    
    
    # ServerAuthorization "admin-kublet": allows unauthenticated access to the
    # "admin" Server from the kubelet, so that Kubernetes health checks can get through.
    apiVersion: policy.linkerd.io/v1beta1
    kind: ServerAuthorization
    metadata:
      namespace: emojivoto
      name: admin-kubelet
    spec:
      server:
        name: admin
      client:
        networks:
          - cidr: 10.244.0.1/32
        unauthenticated: true
    

另外有一个值得注意的是在我们创建 `Server` 资源之后，但在创建 `ServerAuthorization` 之前有一段时间，所有请求都被拒绝。为了避免在实时系统中出现这种情况，我们建议你在部署服务之前创建 policy 资源，或者在创建 `Server` 之前创建 `ServiceAuthorizations`，以便立即授权客户端。

关于授权策略的更多使用可以查看官方文档 https://linkerd.io/2.11/reference/authorization-policy/ 以了解更多相关信息。
