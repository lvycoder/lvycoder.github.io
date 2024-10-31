# ingress-nginx

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/network/ingress-nginx.md "编辑此页")

# ingress-nginx

我们已经了解了 Ingress 资源对象只是一个路由请求描述配置文件，要让其真正生效还需要对应的 Ingress 控制器才行，Ingress 控制器有很多，这里我们先介绍使用最多的 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)，它是基于 Nginx 的 Ingress 控制器。

## 运行原理

`ingress-nginx` 控制器主要是用来组装一个 `nginx.conf` 的配置文件，当配置文件发生任何变动的时候就需要重新加载 Nginx 来生效，但是并不会只在影响 `upstream` 配置的变更后就重新加载 Nginx，控制器内部会使用一个 `lua-nginx-module` 来实现该功能。

我们知道 Kubernetes 控制器使用控制循环模式来检查控制器中所需的状态是否已更新或是否需要变更，所以 `ingress-nginx` 需要使用集群中的不同对象来构建模型，比如 Ingress、Service、Endpoints、Secret、ConfigMap 等可以生成反映集群状态的配置文件的对象，控制器需要一直 Watch 这些资源对象的变化，但是并没有办法知道特定的更改是否会影响到最终生成的 `nginx.conf` 配置文件，所以一旦 Watch 到了任何变化控制器都必须根据集群的状态重建一个新的模型，并将其与当前的模型进行比较，如果模型相同则就可以避免生成新的 Nginx 配置并触发重新加载，否则还需要检查模型的差异是否只和端点有关，如果是这样，则然后需要使用 HTTP POST 请求将新的端点列表发送到在 Nginx 内运行的 Lua 处理程序，并再次避免生成新的 Nginx 配置并触发重新加载，如果运行和新模型之间的差异不仅仅是端点，那么就会基于新模型创建一个新的 Nginx 配置了，这样构建模型最大的一个好处就是在状态没有变化时避免不必要的重新加载，可以节省大量 Nginx 重新加载。

下面简单描述了需要重新加载的一些场景：

  * 创建了新的 Ingress 资源
  * TLS 添加到现有 Ingress
  * 从 Ingress 中添加或删除 path 路径
  * Ingress、Service、Secret 被删除了
  * Ingress 的一些缺失引用对象变可用了，例如 Service 或 Secret
  * 更新了一个 Secret



对于集群规模较大的场景下频繁的对 Nginx 进行重新加载显然会造成大量的性能消耗，所以要尽可能减少出现重新加载的场景。

## 安装

由于 `ingress-nginx` 所在的节点需要能够访问外网，这样域名可以解析到这些节点上直接使用，所以需要让 `ingress-nginx` 绑定节点的 80 和 443 端口，所以可以使用 hostPort 来进行访问，当然对于线上环境来说为了保证高可用，一般是需要运行多个 ·ingress-nginx 实例的，然后可以用一个 nginx/haproxy 作为入口，通过 keepalived 来访问边缘节点的 vip 地址。

边缘节点

所谓的边缘节点即集群内部用来向集群外暴露服务能力的节点，集群外部的服务通过该节点来调用集群内部的服务，边缘节点是集群内外交流的一个 Endpoint。

这里我们使用 Helm Chart（后面会详细讲解）的方式来进行安装：
    
    
    # 如果你不喜欢使用 helm chart 进行安装也可以使用下面的命令一键安装
    # kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml
    ➜ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    ➜ helm repo update
    ➜ helm fetch ingress-nginx/ingress-nginx
    ➜ tar -xvf ingress-nginx-4.0.13.tgz && cd ingress-nginx
    ➜ tree .
    .
    ├── CHANGELOG.md
    ├── Chart.yaml
    ├── OWNERS
    ├── README.md
    ├── ci
    │   ├── controller-custom-ingressclass-flags.yaml
    │   ├── daemonset-customconfig-values.yaml
    │   ├── daemonset-customnodeport-values.yaml
    │   ├── daemonset-headers-values.yaml
    │   ├── daemonset-internal-lb-values.yaml
    │   ├── daemonset-nodeport-values.yaml
    │   ├── daemonset-podannotations-values.yaml
    │   ├── daemonset-tcp-udp-configMapNamespace-values.yaml
    │   ├── daemonset-tcp-udp-values.yaml
    │   ├── daemonset-tcp-values.yaml
    │   ├── deamonset-default-values.yaml
    │   ├── deamonset-metrics-values.yaml
    │   ├── deamonset-psp-values.yaml
    │   ├── deamonset-webhook-and-psp-values.yaml
    │   ├── deamonset-webhook-values.yaml
    │   ├── deployment-autoscaling-behavior-values.yaml
    │   ├── deployment-autoscaling-values.yaml
    │   ├── deployment-customconfig-values.yaml
    │   ├── deployment-customnodeport-values.yaml
    │   ├── deployment-default-values.yaml
    │   ├── deployment-headers-values.yaml
    │   ├── deployment-internal-lb-values.yaml
    │   ├── deployment-metrics-values.yaml
    │   ├── deployment-nodeport-values.yaml
    │   ├── deployment-podannotations-values.yaml
    │   ├── deployment-psp-values.yaml
    │   ├── deployment-tcp-udp-configMapNamespace-values.yaml
    │   ├── deployment-tcp-udp-values.yaml
    │   ├── deployment-tcp-values.yaml
    │   ├── deployment-webhook-and-psp-values.yaml
    │   ├── deployment-webhook-resources-values.yaml
    │   └── deployment-webhook-values.yaml
    ├── templates
    │   ├── NOTES.txt
    │   ├── _helpers.tpl
    │   ├── _params.tpl
    │   ├── admission-webhooks
    │   │   ├── job-patch
    │   │   │   ├── clusterrole.yaml
    │   │   │   ├── clusterrolebinding.yaml
    │   │   │   ├── job-createSecret.yaml
    │   │   │   ├── job-patchWebhook.yaml
    │   │   │   ├── psp.yaml
    │   │   │   ├── role.yaml
    │   │   │   ├── rolebinding.yaml
    │   │   │   └── serviceaccount.yaml
    │   │   └── validating-webhook.yaml
    │   ├── clusterrole.yaml
    │   ├── clusterrolebinding.yaml
    │   ├── controller-configmap-addheaders.yaml
    │   ├── controller-configmap-proxyheaders.yaml
    │   ├── controller-configmap-tcp.yaml
    │   ├── controller-configmap-udp.yaml
    │   ├── controller-configmap.yaml
    │   ├── controller-daemonset.yaml
    │   ├── controller-deployment.yaml
    │   ├── controller-hpa.yaml
    │   ├── controller-ingressclass.yaml
    │   ├── controller-keda.yaml
    │   ├── controller-poddisruptionbudget.yaml
    │   ├── controller-prometheusrules.yaml
    │   ├── controller-psp.yaml
    │   ├── controller-role.yaml
    │   ├── controller-rolebinding.yaml
    │   ├── controller-service-internal.yaml
    │   ├── controller-service-metrics.yaml
    │   ├── controller-service-webhook.yaml
    │   ├── controller-service.yaml
    │   ├── controller-serviceaccount.yaml
    │   ├── controller-servicemonitor.yaml
    │   ├── default-backend-deployment.yaml
    │   ├── default-backend-hpa.yaml
    │   ├── default-backend-poddisruptionbudget.yaml
    │   ├── default-backend-psp.yaml
    │   ├── default-backend-role.yaml
    │   ├── default-backend-rolebinding.yaml
    │   ├── default-backend-service.yaml
    │   ├── default-backend-serviceaccount.yaml
    │   └── dh-param-secret.yaml
    └── values.yaml
    
    4 directories, 81 files
    

Helm Chart 包下载下来后解压就可以看到里面包含的模板文件，其中的 `ci` 目录中就包含了各种场景下面安装的 Values 配置文件，`values.yaml` 文件中包含的是所有可配置的默认值，我们可以对这些默认值进行覆盖，我们这里测试环境就将 master1 节点看成边缘节点，所以我们就直接将 `ingress-nginx` 固定到 master1 节点上，采用 hostNetwork 模式(生产环境可以使用 LB + DaemonSet hostNetwork 模式)，为了避免创建的错误 Ingress 等资源对象影响控制器重新加载，所以我们也强烈建议大家开启准入控制器，`ingess-nginx` 中会提供一个用于校验资源对象的 Admission Webhook，我们可以通过 Values 文件进行开启。然后新建一个名为 `ci/daemonset-prod.yaml` 的 Values 文件，用来覆盖 ingress-nginx 默认的 Values 值。

![主机网络模式](https://picdn.youdianzhishi.com/images/20211216175435.png)

对应的 Values 配置文件如下所示：
    
    
    # ci/daemonset-prod.yaml
    controller:
      name: controller
      image:
        repository: cnych/ingress-nginx
        tag: "v1.1.0"
        digest:
    
      dnsPolicy: ClusterFirstWithHostNet
    
      hostNetwork: true
    
      publishService: # hostNetwork 模式下设置为false，通过节点IP地址上报ingress status数据
        enabled: false
    
      # 是否需要处理不带 ingressClass 注解或者 ingressClassName 属性的 Ingress 对象
      # 设置为 true 会在控制器启动参数中新增一个 --watch-ingress-without-class 标注
      watchIngressWithoutClass: false
    
      kind: DaemonSet
    
      tolerations: # kubeadm 安装的集群默认情况下master是有污点，需要容忍这个污点才可以部署
        - key: "node-role.kubernetes.io/master"
          operator: "Equal"
          effect: "NoSchedule"
    
      nodeSelector: # 固定到master1节点
        kubernetes.io/hostname: master1
    
      service: # HostNetwork 模式不需要创建service
        enabled: false
    
      admissionWebhooks: # 强烈建议开启 admission webhook
        enabled: true
        createSecretJob:
          resources:
            limits:
              cpu: 10m
              memory: 20Mi
            requests:
              cpu: 10m
              memory: 20Mi
        patchWebhookJob:
          resources:
            limits:
              cpu: 10m
              memory: 20Mi
            requests:
              cpu: 10m
              memory: 20Mi
        patch:
          enabled: true
          image:
            repository: cnych/ingress-nginx-webhook-certgen
            tag: v1.1.1
            digest:
    
    defaultBackend: # 配置默认后端
      enabled: true
      name: defaultbackend
      image:
        repository: cnych/ingress-nginx-defaultbackend
        tag: "1.5"
    

然后使用如下命令安装 `ingress-nginx` 应用到 `ingress-nginx` 的命名空间中：
    
    
    ➜ kubectl create ns ingress-nginx
    ➜ helm upgrade --install ingress-nginx . -f ./ci/daemonset-prod.yaml --namespace ingress-nginx
    Release "ingress-nginx" does not exist. Installing it now.
    
    NAME: ingress-nginx
    LAST DEPLOYED: Thu Dec 16 16:47:20 2021
    NAMESPACE: ingress-nginx
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    The ingress-nginx controller has been installed.
    It may take a few minutes for the LoadBalancer IP to be available.
    You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'
    
    An example Ingress that makes use of the controller:
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: example
        namespace: foo
      spec:
        ingressClassName: nginx
        rules:
          - host: www.example.com
            http:
              paths:
                - backend:
                    service:
                      name: exampleService
                      port:
                        number: 80
                  path: /
        # This section is only required if TLS is to be enabled for the Ingress
        tls:
          - hosts:
            - www.example.com
            secretName: example-tls
    
    If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
    
      apiVersion: v1
      kind: Secret
      metadata:
        name: example-tls
        namespace: foo
      data:
        tls.crt: <base64 encoded cert>
        tls.key: <base64 encoded key>
      type: kubernetes.io/tls
    

部署完成后查看 Pod 的运行状态：
    
    
    ➜ kubectl get svc -n ingress-nginx
    NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    ingress-nginx-controller-admission   ClusterIP   10.96.15.99     <none>        443/TCP   11m
    ingress-nginx-defaultbackend         ClusterIP   10.97.250.253   <none>        80/TCP    11m
    ➜ kubectl get pods -n ingress-nginx
    NAME                                            READY   STATUS    RESTARTS   AGE
    ingress-nginx-controller-5dfdd4659c-9g7c2       1/1     Running   0          11m
    ingress-nginx-defaultbackend-84854cd6cb-xb7rv   1/1     Running   0          11m
    ➜ POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx -o jsonpath='{.items[0].metadata.name}')
    ➜ kubectl exec -it $POD_NAME -n ingress-nginx -- /nginx-ingress-controller --version
    kubectl logs -f ingress-nginx-controller-5dfdd4659c-9g7c2 -n ingress-nginxW1216 08:51:22.179213       7 client_config.go:615] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
    I1216 08:51:22.179525       7 main.go:223] "Creating API client" host="https://10.96.0.1:443"
    -------------------------------------------------------------------------------
    NGINX Ingress controller
      Release:       v1.1.0
      Build:         cacbee86b6ccc45bde8ffc184521bed3022e7dee
      Repository:    https://github.com/kubernetes/ingress-nginx
      nginx version: nginx/1.19.9
    
    -------------------------------------------------------------------------------
    
    I1216 08:51:22.198221       7 main.go:267] "Running in Kubernetes cluster" major="1" minor="22" git="v1.22.2" state="clean" commit="8b5a19147530eaac9476b0ab82980b4088bbc1b2" platform="linux/amd64"
    I1216 08:51:22.200478       7 main.go:86] "Valid default backend" service="ingress-nginx/ingress-nginx-defaultbackend"
    I1216 08:51:22.611100       7 main.go:104] "SSL fake certificate created" file="/etc/ingress-controller/ssl/default-fake-certificate.pem"
    I1216 08:51:22.627386       7 ssl.go:531] "loading tls certificate" path="/usr/local/certificates/cert" key="/usr/local/certificates/key"
    I1216 08:51:22.651187       7 nginx.go:255] "Starting NGINX Ingress controller"
    

当看到上面的信息证明 `ingress-nginx` 部署成功了，这里我们安装的是最新版本的控制器，安装完成后会自动创建一个 名为 `nginx` 的 `IngressClass` 对象：
    
    
    ➜ kubectl get ingressclass
    NAME    CONTROLLER             PARAMETERS   AGE
    nginx   k8s.io/ingress-nginx   <none>       18m
    ➜ kubectl get ingressclass nginx -o yaml
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      ......
      name: nginx
      resourceVersion: "1513966"
      uid: 70340e62-cab6-4a11-9982-2108f1db786b
    spec:
      controller: k8s.io/ingress-nginx
    

不过这里我们只提供了一个 `controller` 属性，如果还需要配置一些额外的参数，则可以在安装的 values 文件中进行配置。

## 第一个示例

安装成功后，现在我们来为一个 nginx 应用创建一个 Ingress 资源，如下所示：
    
    
    # my-nginx.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
    spec:
      selector:
        matchLabels:
          app: my-nginx
      template:
        metadata:
          labels:
            app: my-nginx
        spec:
          containers:
            - name: my-nginx
              image: nginx
              ports:
                - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      labels:
        app: my-nginx
    spec:
      ports:
        - port: 80
          protocol: TCP
          name: http
      selector:
        app: my-nginx
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: my-nginx
      namespace: default
    spec:
      ingressClassName: nginx # 使用 nginx 的 IngressClass（关联的 ingress-nginx 控制器）
      rules:
        - host: ngdemo.qikqiak.com # 将域名映射到 my-nginx 服务
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service: # 将所有请求发送到 my-nginx 服务的 80 端口
                    name: my-nginx
                    port:
                      number: 80
    # 不过需要注意大部分Ingress控制器都不是直接转发到Service
    # 而是只是通过Service来获取后端的Endpoints列表，直接转发到Pod，这样可以减少网络跳转，提高性能
    

直接创建上面的资源对象：
    
    
    ➜ kubectl apply -f my-nginx.yaml
    deployment.apps/my-nginx created
    service/my-nginx created
    ingress.networking.k8s.io/my-nginx created
    ➜ kubectl get ingress
    NAME           CLASS    HOSTS                ADDRESS         PORTS   AGE
    my-nginx       nginx    ngdemo.qikqiak.com   192.168.31.31   80      30m
    

在上面的 Ingress 资源对象中我们使用配置 `ingressClassName: nginx` 指定让我们安装的 `ingress-nginx` 这个控制器来处理我们的 Ingress 资源，配置的匹配路径类型为前缀的方式去匹配 `/`，将来自域名 `ngdemo.qikqiak.com` 的所有请求转发到 `my-nginx` 服务的后端 Endpoints 中去。

上面资源创建成功后，然后我们可以将域名 `ngdemo.qikqiak.com` 解析到 `ingress-nginx` 所在的**边缘节点** 中的任意一个，当然也可以在本地 `/etc/hosts` 中添加对应的映射也可以，然后就可以通过域名进行访问了。

![ngdemo](https://picdn.youdianzhishi.com/images/20211216172653.png)

下图显示了客户端是如何通过 Ingress 控制器连接到其中一个 Pod 的流程，客户端首先对 `ngdemo.qikqiak.com` 执行 DNS 解析，得到 Ingress 控制器所在节点的 IP，然后客户端向 Ingress 控制器发送 HTTP 请求，然后根据 Ingress 对象里面的描述匹配域名，找到对应的 Service 对象，并获取关联的 Endpoints 列表，将客户端的请求转发给其中一个 Pod。

![ingress controller workflow](https://picdn.youdianzhishi.com/images/ingress-controller-workflow.png)

前面我们也提到了 `ingress-nginx` 控制器的核心原理就是将我们的 `Ingress` 这些资源对象映射翻译成 Nginx 配置文件 `nginx.conf`，我们可以通过查看控制器中的配置文件来验证这点：
    
    
    ➜ kubectl exec -it $POD_NAME -n ingress-nginx -- cat /etc/nginx/nginx.conf
    
    ......
    upstream upstream_balancer {
            server 0.0.0.1; # placeholder
            balancer_by_lua_block {
                    balancer.balance()
            }
            keepalive 320;
            keepalive_timeout  60s;
            keepalive_requests 10000;
    }
    
    ......
    ## start server ngdemo.qikqiak.com
    server {
            server_name ngdemo.qikqiak.com ;
    
            listen 80  ;
            listen [::]:80  ;
            listen 443  ssl http2 ;
            listen [::]:443  ssl http2 ;
    
            set $proxy_upstream_name "-";
    
            ssl_certificate_by_lua_block {
                    certificate.call()
            }
    
            location / {
    
                    set $namespace      "default";
                    set $ingress_name   "my-nginx";
                    set $service_name   "my-nginx";
                    set $service_port   "80";
                    set $location_path  "/";
                    set $global_rate_limit_exceeding n;
                    ......
                    proxy_next_upstream_timeout             0;
                    proxy_next_upstream_tries               3;
    
                    proxy_pass http://upstream_balancer;
    
                    proxy_redirect                          off;
    
            }
    
    }
    ## end server ngdemo.qikqiak.com
    ......
    

我们可以在 `nginx.conf` 配置文件中看到上面我们新增的 Ingress 资源对象的相关配置信息，不过需要注意的是现在并不会为每个 backend 后端都创建一个 `upstream` 配置块，现在是使用 Lua 程序进行动态处理的，所以我们没有直接看到后端的 Endpoints 相关配置数据。

## Nginx 配置

如果我们还想进行一些自定义配置，则有几种方式可以实现：使用 Configmap 在 Nginx 中设置全局配置、通过 Ingress 的 Annotations 设置特定 Ingress 的规则、自定义模板。接下来我们重点给大家介绍使用注解来对 Ingress 对象进行自定义。

### Basic Auth

我们可以在 Ingress 对象上配置一些基本的 Auth 认证，比如 Basic Auth，可以用 `htpasswd` 生成一个密码文件来验证身份验证。
    
    
    ➜ htpasswd -c auth foo
    New password:
    Re-type new password:
    Adding password for user foo
    

然后根据上面的 auth 文件创建一个 secret 对象：
    
    
    ➜ kubectl create secret generic basic-auth --from-file=auth
    secret/basic-auth created
    ➜ kubectl get secret basic-auth -o yaml
    apiVersion: v1
    data:
      auth: Zm9vOiRhcHIxJFUxYlFZTFVoJHdIZUZQQ1dyZTlGRFZONTQ0dXVQdC4K
    kind: Secret
    metadata:
      name: basic-auth
      namespace: default
    type: Opaque
    

然后对上面的 my-nginx 应用创建一个具有 Basic Auth 的 Ingress 对象：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: ingress-with-auth
      namespace: default
      annotations:
        nginx.ingress.kubernetes.io/auth-type: basic # 认证类型
        nginx.ingress.kubernetes.io/auth-secret: basic-auth # 包含 user/password 定义的 secret 对象名
        nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - foo" # 要显示的带有适当上下文的消息，说明需要身份验证的原因
    spec:
      ingressClassName: nginx # 使用 nginx 的 IngressClass（关联的 ingress-nginx 控制器）
      rules:
        - host: bauth.qikqiak.com # 将域名映射到 my-nginx 服务
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service: # 将所有请求发送到 my-nginx 服务的 80 端口
                    name: my-nginx
                    port:
                      number: 80
    

直接创建上面的资源对象，然后通过下面的命令或者在浏览器中直接打开配置的域名：
    
    
    ➜ kubectl get ingress
    NAME                CLASS    HOSTS                        ADDRESS         PORTS   AGE
    ingress-with-auth   nginx    bauth.qikqiak.com            192.168.31.31   80      6m55s
    ➜ curl -v http://192.168.31.31 -H 'Host: bauth.qikqiak.com'
    *   Trying 192.168.31.31...
    * TCP_NODELAY set
    * Connected to 192.168.31.31 (192.168.31.31) port 80 (#0)
    > GET / HTTP/1.1
    > Host: bauth.qikqiak.com
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    < HTTP/1.1 401 Unauthorized
    < Date: Thu, 16 Dec 2021 10:49:03 GMT
    < Content-Type: text/html
    < Content-Length: 172
    < Connection: keep-alive
    < WWW-Authenticate: Basic realm="Authentication Required - foo"
    <
    <html>
    <head><title>401 Authorization Required</title></head>
    <body>
    <center><h1>401 Authorization Required</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    * Connection #0 to host 192.168.31.31 left intact
    * Closing connection 0
    

我们可以看到出现了 401 认证失败错误，然后带上我们配置的用户名和密码进行认证：
    
    
    ➜ curl -v http://192.168.31.31 -H 'Host: bauth.qikqiak.com' -u 'foo:foo'
    *   Trying 192.168.31.31...
    * TCP_NODELAY set
    * Connected to 192.168.31.31 (192.168.31.31) port 80 (#0)
    * Server auth using Basic with user 'foo'
    > GET / HTTP/1.1
    > Host: bauth.qikqiak.com
    > Authorization: Basic Zm9vOmZvbw==
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 16 Dec 2021 10:49:38 GMT
    < Content-Type: text/html
    < Content-Length: 615
    < Connection: keep-alive
    < Last-Modified: Tue, 02 Nov 2021 14:49:22 GMT
    < ETag: "61814ff2-267"
    < Accept-Ranges: bytes
    <
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
    * Connection #0 to host 192.168.31.31 left intact
    * Closing connection 0
    

可以看到已经认证成功了。除了可以使用我们自己在本地集群创建的 Auth 信息之外，还可以使用外部的 Basic Auth 认证信息，比如我们使用 `https://httpbin.org` 的外部 Basic Auth 认证，创建如下所示的 Ingress 资源对象：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      annotations:
        # 配置外部认证服务地址
        nginx.ingress.kubernetes.io/auth-url: https://httpbin.org/basic-auth/user/passwd
      name: external-auth
      namespace: default
    spec:
      ingressClassName: nginx
      rules:
        - host: external-bauth.qikqiak.com
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: my-nginx
                    port:
                      number: 80
    

上面的资源对象创建完成后，再进行简单的测试：
    
    
    ➜ kubectl get ingress
    NAME                CLASS    HOSTS                        ADDRESS         PORTS   AGE
    external-auth       <none>   external-bauth.qikqiak.com                   80      72s
    ➜ curl -k http://192.168.31.31 -v -H 'Host: external-bauth.qikqiak.com'
    *   Trying 192.168.31.31...
    * TCP_NODELAY set
    * Connected to 192.168.31.31 (192.168.31.31) port 80 (#0)
    > GET / HTTP/1.1
    > Host: external-bauth.qikqiak.com
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    < HTTP/1.1 401 Unauthorized
    < Date: Thu, 16 Dec 2021 10:57:25 GMT
    < Content-Type: text/html
    < Content-Length: 172
    < Connection: keep-alive
    < WWW-Authenticate: Basic realm="Fake Realm"
    <
    <html>
    <head><title>401 Authorization Required</title></head>
    <body>
    <center><h1>401 Authorization Required</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    * Connection #0 to host 192.168.31.31 left intact
    * Closing connection 0
    

然后使用正确的用户名和密码测试：
    
    
    ➜ curl -k http://192.168.31.31 -v -H 'Host: external-bauth.qikqiak.com' -u 'user:passwd'
    *   Trying 192.168.31.31...
    * TCP_NODELAY set
    * Connected to 192.168.31.31 (192.168.31.31) port 80 (#0)
    * Server auth using Basic with user 'user'
    > GET / HTTP/1.1
    > Host: external-bauth.qikqiak.com
    > Authorization: Basic dXNlcjpwYXNzd2Q=
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 16 Dec 2021 10:58:31 GMT
    < Content-Type: text/html
    < Content-Length: 615
    < Connection: keep-alive
    < Last-Modified: Tue, 02 Nov 2021 14:49:22 GMT
    < ETag: "61814ff2-267"
    < Accept-Ranges: bytes
    <
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
    * Connection #0 to host 192.168.31.31 left intact
    * Closing connection 0
    

如果用户名或者密码错误则同样会出现 401 的状态码：
    
    
    ➜ curl -k http://192.168.31.31 -v -H 'Host: external-bauth.qikqiak.com' -u 'user:passwd123'
    *   Trying 192.168.31.31...
    * TCP_NODELAY set
    * Connected to 192.168.31.31 (192.168.31.31) port 80 (#0)
    * Server auth using Basic with user 'user'
    > GET / HTTP/1.1
    > Host: external-bauth.qikqiak.com
    > Authorization: Basic dXNlcjpwYXNzd2QxMjM=
    > User-Agent: curl/7.64.1
    > Accept: */*
    >
    < HTTP/1.1 401 Unauthorized
    < Date: Thu, 16 Dec 2021 10:59:18 GMT
    < Content-Type: text/html
    < Content-Length: 172
    < Connection: keep-alive
    * Authentication problem. Ignoring this.
    < WWW-Authenticate: Basic realm="Fake Realm"
    <
    <html>
    <head><title>401 Authorization Required</title></head>
    <body>
    <center><h1>401 Authorization Required</h1></center>
    <hr><center>nginx</center>
    </body>
    </html>
    * Connection #0 to host 192.168.31.31 left intact
    * Closing connection 0
    

当然除了 Basic Auth 这一种简单的认证方式之外，`ingress-nginx` 还支持一些其他高级的认证，比如我们可以使用 GitHub OAuth 来认证 Kubernetes 的 Dashboard。

### URL Rewrite

`ingress-nginx` 很多高级的用法可以通过 Ingress 对象的 `annotation` 进行配置，比如常用的 URL Rewrite 功能。很多时候我们会将 `ingress-nginx` 当成网关使用，比如对访问的服务加上 `/app` 这样的前缀，在 `nginx` 的配置里面我们知道有一个 `proxy_pass` 指令可以实现：
    
    
    location /app/ {
      proxy_pass http://127.0.0.1/remote/;
    }
    

`proxy_pass` 后面加了 `/remote` 这个路径，此时会将匹配到该规则路径中的 `/app` 用 `/remote` 替换掉，相当于截掉路径中的 `/app`。同样的在 Kubernetes 中使用 `ingress-nginx` 又该如何来实现呢？我们可以使用 `rewrite-target` 的注解来实现这个需求，比如现在我们想要通过 `rewrite.qikqiak.com/gateway/` 来访问到 Nginx 服务，则我们需要对访问的 URL 路径做一个 Rewrite，在 PATH 中添加一个 gateway 的前缀，关于 Rewrite 的操作在 [ingress-nginx 官方文档](https://kubernetes.github.io/ingress-nginx/examples/rewrite/)中也给出对应的说明:

![ingress nginx rewrite](https://picdn.youdianzhishi.com/images/ingress-nginx-rewrite-list.png)

按照要求我们需要在 `path` 中匹配前缀 `gateway`，然后通过 `rewrite-target` 指定目标，Ingress 对象如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: rewrite
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /$2
    spec:
      ingressClassName: nginx
      rules:
        - host: rewrite.qikqiak.com
          http:
            paths:
              - path: /gateway(/|$)(.*)
                pathType: Prefix
                backend:
                  service:
                    name: my-nginx
                    port:
                      number: 80
    

更新后，我们可以预见到直接访问域名肯定是不行了，因为我们没有匹配 `/` 的 path 路径：
    
    
    ➜ curl rewrite.qikqiak.com
    default backend - 404
    

但是我们带上 `gateway` 的前缀再去访问:

![ingress nginx rewrite](https://picdn.youdianzhishi.com/images/20211219180809.png)

我们可以看到已经可以访问到了，这是因为我们在 `path` 中通过正则表达式 `/gateway(/|$)(.*)` 将匹配的路径设置成了 `rewrite-target` 的目标路径了，所以我们访问 `rewite.qikqiak.com/gateway/` 的时候实际上相当于访问的就是后端服务的 `/` 路径。

要解决我们访问主域名出现 404 的问题，我们可以给应用设置一个 `app-root` 的注解，这样当我们访问主域名的时候会自动跳转到我们指定的 `app-root` 目录下面，如下所示：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: rewrite
      annotations:
        nginx.ingress.kubernetes.io/app-root: /gateway/
        nginx.ingress.kubernetes.io/rewrite-target: /$2
    spec:
      ingressClassName: nginx
      rules:
        - host: rewrite.qikqiak.com
          http:
            paths:
              - path: /gateway(/|$)(.*)
                pathType: Prefix
                backend:
                  service:
                    name: my-nginx
                    port:
                      number: 80
    

这个时候我们更新应用后访问主域名 `rewrite.qikqiak.com` 就会自动跳转到 `rewrite.qikqiak.com/gateway/` 路径下面去了。但是还有一个问题是我们的 path 路径其实也匹配了 `/app` 这样的路径，可能我们更加希望我们的应用在最后添加一个 `/` 这样的 slash，同样我们可以通过 `configuration-snippet` 配置来完成，如下 Ingress 对象：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: rewrite
      annotations:
        nginx.ingress.kubernetes.io/app-root: /gateway/
        nginx.ingress.kubernetes.io/rewrite-target: /$2
        nginx.ingress.kubernetes.io/configuration-snippet: |
          rewrite ^(/gateway)$ $1/ redirect;
    spec:
      ingressClassName: nginx
      rules:
        - host: rewrite.qikqiak.com
          http:
            paths:
              - path: /gateway(/|$)(.*)
                pathType: Prefix
                backend:
                  service:
                    name: my-nginx
                    port:
                      number: 80
    

更新后我们的应用就都会以 `/` 这样的 slash 结尾了。这样就完成了我们的需求，如果你原本对 nginx 的配置就非常熟悉的话应该可以很快就能理解这种配置方式了。

### 灰度发布

在日常工作中我们经常需要对服务进行版本更新升级，所以我们经常会使用到滚动升级、蓝绿发布、灰度发布等不同的发布操作。而 `ingress-nginx` 支持通过 Annotations 配置来实现不同场景下的灰度发布和测试，可以满足金丝雀发布、蓝绿部署与 A/B 测试等业务场景。

[ingress-nginx 的 Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary) 支持以下 4 种 Canary 规则：

  * `nginx.ingress.kubernetes.io/canary-by-header`：基于 Request Header 的流量切分，适用于灰度发布以及 A/B 测试。当 Request Header 设置为 always 时，请求将会被一直发送到 Canary 版本；当 Request Header 设置为 never 时，请求不会被发送到 Canary 入口；对于任何其他 Header 值，将忽略 Header，并通过优先级将请求与其他金丝雀规则进行优先级的比较。
  * `nginx.ingress.kubernetes.io/canary-by-header-value`：要匹配的 Request Header 的值，用于通知 Ingress 将请求路由到 Canary Ingress 中指定的服务。当 Request Header 设置为此值时，它将被路由到 Canary 入口。该规则允许用户自定义 Request Header 的值，必须与上一个 annotation (`canary-by-header`) 一起使用。
  * `nginx.ingress.kubernetes.io/canary-weight`：基于服务权重的流量切分，适用于蓝绿部署，权重范围 0 - 100 按百分比将请求路由到 Canary Ingress 中指定的服务。权重为 0 意味着该金丝雀规则不会向 Canary 入口的服务发送任何请求，权重为 100 意味着所有请求都将被发送到 Canary 入口。
  * `nginx.ingress.kubernetes.io/canary-by-cookie`：基于 cookie 的流量切分，适用于灰度发布与 A/B 测试。用于通知 Ingress 将请求路由到 Canary Ingress 中指定的服务的 cookie。当 cookie 值设置为 always 时，它将被路由到 Canary 入口；当 cookie 值设置为 never 时，请求不会被发送到 Canary 入口；对于任何其他值，将忽略 cookie 并将请求与其他金丝雀规则进行优先级的比较。



> 需要注意的是金丝雀规则按优先顺序进行排序：`canary-by-header - > canary-by-cookie - > canary-weight`

总的来说可以把以上的四个 annotation 规则划分为以下两类：

  * 基于权重的 Canary 规则 ![基于权重的 Canary 规则](https://picdn.youdianzhishi.com/images/20201213130834.png)

  * 基于用户请求的 Canary 规则 ![基于用户请求的 Canary 规则](https://picdn.youdianzhishi.com/images/20201213130856.png)




下面我们通过一个示例应用来对灰度发布功能进行说明。

**第一步. 部署 Production 应用**

首先创建一个 production 环境的应用资源清单：
    
    
    # production.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: production
      labels:
        app: production
    spec:
      selector:
        matchLabels:
          app: production
      template:
        metadata:
          labels:
            app: production
        spec:
          containers:
            - name: production
              image: cnych/echoserver
              ports:
                - containerPort: 8080
              env:
                - name: NODE_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: spec.nodeName
                - name: POD_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.name
                - name: POD_NAMESPACE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.namespace
                - name: POD_IP
                  valueFrom:
                    fieldRef:
                      fieldPath: status.podIP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: production
      labels:
        app: production
    spec:
      ports:
        - port: 80
          targetPort: 8080
          name: http
      selector:
        app: production
    

然后创建一个用于 production 环境访问的 Ingress 资源对象：
    
    
    # production-ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: production
    spec:
      ingressClassName: nginx
      rules:
        - host: echo.qikqiak.com
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: production
                    port:
                      number: 80
    

直接创建上面的几个资源对象：
    
    
    ➜ kubectl apply -f production.yaml
    ➜ kubectl apply -f production-ingress.yaml
    ➜ kubectl get pods -l app=production
    NAME                         READY   STATUS    RESTARTS   AGE
    production-856d5fb99-d6bds   1/1     Running   0          2m50s
    ➜ kubectl get ingress
    NAME         CLASS    HOSTS                ADDRESS        PORTS   AGE
    production   <none>   echo.qikqiak.com     10.151.30.11   80      90s
    

应用部署成功后，将域名 `echo.qikqiak.com` 映射到 master1 节点（ingress-nginx 所在的节点）的 IP 即可正常访问应用：
    
    
    ➜ curl http://echo.qikqiak.com
    
    Hostname: production-856d5fb99-d6bds
    
    Pod Information:
        node name:  node1
        pod name:   production-856d5fb99-d6bds
        pod namespace:  default
        pod IP: 10.244.1.111
    
    Server values:
        server_version=nginx: 1.13.3 - lua: 10008
    
    Request Information:
        client_address=10.244.0.0
        method=GET
        real path=/
        query=
        request_version=1.1
        request_scheme=http
        request_uri=http://echo.qikqiak.com:8080/
    
    Request Headers:
        accept=*/*
        host=echo.qikqiak.com
        user-agent=curl/7.64.1
        x-forwarded-for=171.223.99.184
        x-forwarded-host=echo.qikqiak.com
        x-forwarded-port=80
        x-forwarded-proto=http
        x-real-ip=171.223.99.184
        x-request-id=e680453640169a7ea21afba8eba9e116
        x-scheme=http
    
    Request Body:
        -no body in request-
    

**第二步. 创建 Canary 版本** 参考将上述 Production 版本的 `production.yaml` 文件，再创建一个 Canary 版本的应用。
    
    
    # canary.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: canary
      labels:
        app: canary
    spec:
      selector:
        matchLabels:
          app: canary
      template:
        metadata:
          labels:
            app: canary
        spec:
          containers:
            - name: canary
              image: cnych/echoserver
              ports:
                - containerPort: 8080
              env:
                - name: NODE_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: spec.nodeName
                - name: POD_NAME
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.name
                - name: POD_NAMESPACE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.namespace
                - name: POD_IP
                  valueFrom:
                    fieldRef:
                      fieldPath: status.podIP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: canary
      labels:
        app: canary
    spec:
      ports:
        - port: 80
          targetPort: 8080
          name: http
      selector:
        app: canary
    

接下来就可以通过配置 Annotation 规则进行流量切分了。

**第三步. Annotation 规则配置**

**1\. 基于权重** ：基于权重的流量切分的典型应用场景就是蓝绿部署，可通过将权重设置为 0 或 100 来实现。例如，可将 Green 版本设置为主要部分，并将 Blue 版本的入口配置为 Canary。最初，将权重设置为 0，因此不会将流量代理到 Blue 版本。一旦新版本测试和验证都成功后，即可将 Blue 版本的权重设置为 100，即所有流量从 Green 版本转向 Blue。

创建一个基于权重的 Canary 版本的应用路由 Ingress 对象。
    
    
    # canary-ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: canary
      annotations:
        nginx.ingress.kubernetes.io/canary: "true" # 要开启灰度发布机制，首先需要启用 Canary
        nginx.ingress.kubernetes.io/canary-weight: "30" # 分配30%流量到当前Canary版本
    spec:
      ingressClassName: nginx
      rules:
        - host: echo.qikqiak.com
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: canary
                    port:
                      number: 80
    

直接创建上面的资源对象即可：
    
    
    ➜ kubectl apply -f canary.yaml
    ➜ kubectl apply -f canary-ingress.yaml
    ➜ kubectl get pods
    NAME                         READY   STATUS    RESTARTS   AGE
    canary-66cb497b7f-48zx4      1/1     Running   0          7m48s
    production-856d5fb99-d6bds   1/1     Running   0          21m
    ......
    ➜ kubectl get svc
    NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
    canary                     ClusterIP   10.106.91.106    <none>        80/TCP                       8m23s
    production                 ClusterIP   10.105.182.15    <none>        80/TCP                       22m
    ......
    ➜ kubectl get ingress
    NAME         CLASS    HOSTS                ADDRESS        PORTS   AGE
    canary       <none>   echo.qikqiak.com     10.151.30.11   80      108s
    production   <none>   echo.qikqiak.com     10.151.30.11   80      22m
    

Canary 版本应用创建成功后，接下来我们在命令行终端中来不断访问这个应用，观察 Hostname 变化：
    
    
    ➜ for i in $(seq 1 10); do curl -s echo.qikqiak.com | grep "Hostname"; done
    Hostname: production-856d5fb99-d6bds
    Hostname: canary-66cb497b7f-48zx4
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: production-856d5fb99-d6bds
    

由于我们给 Canary 版本应用分配了 30% 左右权重的流量，所以上面我们访问 10 次有 3 次访问到了 Canary 版本的应用，符合我们的预期。

**2\. 基于 Request Header** : 基于 Request Header 进行流量切分的典型应用场景即灰度发布或 A/B 测试场景。

在上面的 Canary 版本的 Ingress 对象中新增一条 annotation 配置 `nginx.ingress.kubernetes.io/canary-by-header: canary`（这里的 value 可以是任意值），使当前的 Ingress 实现基于 Request Header 进行流量切分，由于 `canary-by-header` 的优先级大于 `canary-weight`，所以会忽略原有的 `canary-weight` 的规则。
    
    
    annotations:
      nginx.ingress.kubernetes.io/canary: "true" # 要开启灰度发布机制，首先需要启用 Canary
      nginx.ingress.kubernetes.io/canary-by-header: canary # 基于header的流量切分
      nginx.ingress.kubernetes.io/canary-weight: "30" # 会被忽略，因为配置了 canary-by-headerCanary版本
    

更新上面的 Ingress 资源对象后，我们在请求中加入不同的 Header 值，再次访问应用的域名。

> 注意：当 Request Header 设置为 never 或 always 时，请求将不会或一直被发送到 Canary 版本，对于任何其他 Header 值，将忽略 Header，并通过优先级将请求与其他 Canary 规则进行优先级的比较。
    
    
    ➜ for i in $(seq 1 10); do curl -s -H "canary: never" echo.qikqiak.com | grep "Hostname"; done
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    

这里我们在请求的时候设置了 `canary: never` 这个 Header 值，所以请求没有发送到 Canary 应用中去。如果设置为其他值呢：
    
    
    ➜ for i in $(seq 1 10); do curl -s -H "canary: other-value" echo.qikqiak.com | grep "Hostname"; done
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: canary-66cb497b7f-48zx4
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: production-856d5fb99-d6bds
    Hostname: canary-66cb497b7f-48zx4
    Hostname: production-856d5fb99-d6bds
    Hostname: canary-66cb497b7f-48zx4
    

由于我们请求设置的 Header 值为 `canary: other-value`，所以 ingress-nginx 会通过优先级将请求与其他 Canary 规则进行优先级的比较，我们这里也就会进入 `canary-weight: "30"` 这个规则去。

这个时候我们可以在上一个 annotation (即 `canary-by-header`）的基础上添加一条 `nginx.ingress.kubernetes.io/canary-by-header-value: user-value` 这样的规则，就可以将请求路由到 Canary Ingress 中指定的服务了。
    
    
    annotations:
      nginx.ingress.kubernetes.io/canary: "true" # 要开启灰度发布机制，首先需要启用 Canary
      nginx.ingress.kubernetes.io/canary-by-header-value: user-value
      nginx.ingress.kubernetes.io/canary-by-header: canary # 基于header的流量切分
      nginx.ingress.kubernetes.io/canary-weight: "30" # 分配30%流量到当前Canary版本
    

同样更新 Ingress 对象后，重新访问应用，当 Request Header 满足 `canary: user-value`时，所有请求就会被路由到 Canary 版本：
    
    
    ➜ for i in $(seq 1 10); do curl -s -H "canary: user-value" echo.qikqiak.com | grep "Hostname"; done
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    

**3\. 基于 Cookie** ：与基于 Request Header 的 annotation 用法规则类似。例如在 A/B 测试场景下，需要让地域为北京的用户访问 Canary 版本。那么当 cookie 的 annotation 设置为 `nginx.ingress.kubernetes.io/canary-by-cookie: "users_from_Beijing"`，此时后台可对登录的用户请求进行检查，如果该用户访问源来自北京则设置 cookie `users_from_Beijing` 的值为 `always`，这样就可以确保北京的用户仅访问 Canary 版本。

同样我们更新 Canary 版本的 Ingress 资源对象，采用基于 Cookie 来进行流量切分，
    
    
    annotations:
      nginx.ingress.kubernetes.io/canary: "true" # 要开启灰度发布机制，首先需要启用 Canary
      nginx.ingress.kubernetes.io/canary-by-cookie: "users_from_Beijing" # 基于 cookie
      nginx.ingress.kubernetes.io/canary-weight: "30" # 会被忽略，因为配置了 canary-by-cookie
    

更新上面的 Ingress 资源对象后，我们在请求中设置一个 `users_from_Beijing=always` 的 Cookie 值，再次访问应用的域名。
    
    
    ➜ for i in $(seq 1 10); do curl -s -b "users_from_Beijing=always" echo.qikqiak.com | grep "Hostname"; done
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    Hostname: canary-66cb497b7f-48zx4
    

我们可以看到应用都被路由到了 Canary 版本的应用中去了，如果我们将这个 Cookie 值设置为 never，则不会路由到 Canary 应用中。

### HTTPS

如果我们需要用 HTTPS 来访问我们这个应用的话，就需要监听 443 端口了，同样用 HTTPS 访问应用必然就需要证书，这里我们用 `openssl` 来创建一个自签名的证书：
    
    
    ➜ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=foo.bar.com"
    

然后通过 Secret 对象来引用证书文件：
    
    
    # 要注意证书文件名称必须是 tls.crt 和 tls.key
    ➜ kubectl create secret tls foo-tls --cert=tls.crt --key=tls.key
    secret/who-tls created
    

这个时候我们就可以创建一个 HTTPS 访问应用的：
    
    
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: ingress-with-auth
      annotations:
        # 认证类型
        nginx.ingress.kubernetes.io/auth-type: basic
        # 包含 user/password 定义的 secret 对象名
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
        # 要显示的带有适当上下文的消息，说明需要身份验证的原因
        nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - foo"
    spec:
      ingressClassName: nginx
      tls: # 配置 tls 证书
        - hosts:
            - foo.bar.com
          secretName: foo-tls
      rules:
        - host: foo.bar.com
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: my-nginx
                    port:
                      number: 80
    

除了自签名证书或者购买正规机构的 CA 证书之外，我们还可以通过一些工具来自动生成合法的证书，[cert-manager](https://cert-manager.io/) 是一个云原生证书管理开源项目，可以用于在 Kubernetes 集群中提供 HTTPS 证书并自动续期，支持 `Let's Encrypt/HashiCorp/Vault` 这些免费证书的签发。在 Kubernetes 中，可以通过 Kubernetes Ingress 和 Let's Encrypt 实现外部服务的自动化 HTTPS。

### TCP 与 UDP

由于在 Ingress 资源对象中没有直接对 TCP 或 UDP 服务的支持，要在 `ingress-nginx` 中提供支持，需要在控制器启动参数中添加 `--tcp-services-configmap` 和 `--udp-services-configmap` 标志指向一个 ConfigMap，其中的 key 是要使用的外部端口，value 值是使用格式 `<namespace/service name>:<service port>:[PROXY]:[PROXY]` 暴露的服务，端口可以使用端口号或者端口名称，最后两个字段是可选的，用于配置 PROXY 代理。

比如现在我们要通过 `ingress-nginx` 来暴露一个 MongoDB 服务，首先创建如下的应用：
    
    
    # mongo.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mongo
      labels:
        app: mongo
    spec:
      selector:
        matchLabels:
          app: mongo
      template:
        metadata:
          labels:
            app: mongo
        spec:
          volumes:
            - name: data
              emptyDir: {}
          containers:
            - name: mongo
              image: mongo:4.0
              ports:
                - containerPort: 27017
              volumeMounts:
                - name: data
                  mountPath: /data/db
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mongo
    spec:
      selector:
        app: mongo
      ports:
        - port: 27017
    

直接创建上面的资源对象：
    
    
    ➜ kubectl apply -f mongo.yaml
    ➜ kubectl get svc
    NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
    mongo           ClusterIP   10.98.117.228    <none>        27017/TCP   2m26s
    ➜ kubectl get pods -l app=mongo
    NAME                     READY   STATUS    RESTARTS   AGE
    mongo-84c587f547-gd7pv   1/1     Running   0          2m5s
    

现在我们要通过 `ingress-nginx` 来暴露上面的 MongoDB 服务，我们需要创建一个如下所示的 ConfigMap：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: tcp-services
      namespace: ingress-nginx
    data:
      "27017": default/mongo:27017
    

然后在 `ingress-nginx` 的启动参数中添加 `--tcp-services-configmap=$(POD_NAMESPACE)/ingress-nginx-tcp` 这样的配置即可，由于我们这里使用的是 Helm Chart 进行安装的，我们只需要去覆盖 Values 值重新安装即可，修改 `ci/daemonset-prod.yaml` 文件：
    
    
    # ci/daemonset-prod.yaml
    # ...... 其他部分省略，和之前的保持一致
    
    tcp: # 配置 tcp 服务
      27017: "default/mongo:27017" # 使用 27017 端口去映射 mongo 服务
      # 9000: "default/test:8080"   # 如果还需要暴露其他 TCP 服务，继续添加即可
    

配置完成后重新更新当前的 `ingress-nginx`：
    
    
    ➜ helm upgrade --install ingress-nginx . -f ./ci/daemonset-prod.yaml --namespace ingress-nginx
    

重新部署完成后会自动生成一个名为 `ingress-nginx-tcp` 的 ConfigMap 对象，如下所示：
    
    
    ➜ kubectl get configmap -n ingress-nginx ingress-nginx-tcp -o yaml
    apiVersion: v1
    data:
      "27017": default/mongo:27017
    kind: ConfigMap
    metadata:
      ......
      name: ingress-nginx-tcp
      namespace: ingress-nginx
    

在 `ingress-nginx` 的启动参数中也添加上 `--tcp-services-configmap=$(POD_NAMESPACE)/ingress-nginx-tcp` 这样的配置：
    
    
    ➜ kubectl get pods -n ingress-nginx
    NAME                                            READY   STATUS    RESTARTS        AGE
    ingress-nginx-controller-gc582                  1/1     Running   0               5m17s
    ➜ kubectl get pod ingress-nginx-controller-gc582 -n ingress-nginx -o yaml
    apiVersion: v1
    kind: Pod
    ......
      containers:
      - args:
        - /nginx-ingress-controller
        - --default-backend-service=$(POD_NAMESPACE)/ingress-nginx-defaultbackend
        - --election-id=ingress-controller-leader
        - --controller-class=k8s.io/ingress-nginx
        - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
        - --tcp-services-configmap=$(POD_NAMESPACE)/ingress-nginx-tcp  # tcp 配置参数
        - --validating-webhook=:8443
        - --validating-webhook-certificate=/usr/local/certificates/cert
        - --validating-webhook-key=/usr/local/certificates/key
    ......
        ports:
    ......
        - containerPort: 27017
          hostPort: 27017
          name: 27017-tcp
          protocol: TCP
    ......
    

现在我们就可以通过 `ingress-nginx` 暴露的 27017 端口去访问 Mongo 服务了：
    
    
    ➜ mongo --host 192.168.31.31 --port 27017
    MongoDB shell version v4.0.3
    connecting to: mongodb://192.168.31.31:27017/
    Implicit session: session { "id" : UUID("10f462eb-32b8-443b-ad85-99820db1aaa0") }
    MongoDB server version: 4.0.27
    ......
    
    > show dbs
    admin   0.000GB
    config  0.000GB
    local   0.000GB
    >
    

同样的我们也可以去查看最终生成的 `nginx.conf` 配置文件：
    
    
    ➜ kubectl exec -it ingress-nginx-controller-gc582 -n ingress-nginx -- cat /etc/nginx/nginx.conf
    ......
    stream {
        ......
        # TCP services
        server {
                preread_by_lua_block {
                        ngx.var.proxy_upstream_name="tcp-default-mongo-27017";
                }
                listen                  27017;
                listen                  [::]:27017;
                proxy_timeout           600s;
                proxy_next_upstream     on;
                proxy_next_upstream_timeout 600s;
                proxy_next_upstream_tries   3;
                proxy_pass              upstream_balancer;
        }
        # UDP services
    }
    

TCP 相关的配置位于 `stream` 配置块下面。从 Nginx 1.9.13 版本开始提供 UDP 负载均衡，同样我们也可以在 `ingress-nginx` 中来代理 UDP 服务，比如我们可以去暴露 `kube-dns` 的服务，同样需要创建一个如下所示的 ConfigMap：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: udp-services
      namespace: ingress-nginx
    data:
      53: "kube-system/kube-dns:53"
    

然后需要在 `ingress-nginx` 参数中添加一个 `- --udp-services-configmap=$(POD_NAMESPACE)/udp-services` 这样的配置，当然我们这里只需要去修改 Values 文件值即可，修改 `ci/daemonset-prod.yaml` 文件：
    
    
    # ci/daemonset-prod.yaml
    # ...... 其他部分省略，和之前的保持一致
    
    tcp: # 配置 tcp 服务
      27017: "default/mongo:27017" # 使用 27017 端口去映射 mongo 服务
      # 9000: "default/test:8080"   # 如果还需要暴露其他 TCP 服务，继续添加即可
    
    udp: # 配置 udp 服务
      53: "kube-system/kube-dns:53"
    

然后重新更新即可。

### 全局配置

除了可以通过 `annotations` 对指定的 Ingress 进行定制之外，我们还可以配置 `ingress-nginx` 的全局配置，在控制器启动参数中通过标志 `--configmap` 指定了一个全局的 ConfigMap 对象，我们可以将全局的一些配置直接定义在该对象中即可：
    
    
    containers:
      - args:
        - /nginx-ingress-controller
        - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
        ......
    

比如这里我们用于全局配置的 ConfigMap 名为 `ingress-nginx-controller`：
    
    
    ➜ kubectl get configmap -n ingress-nginx
    NAME                        DATA   AGE
    ingress-nginx-controller    1      5d2h
    

比如我们可以添加如下所示的一些常用配置：
    
    
    ➜ kubectl edit configmap ingress-nginx-controller -n ingress-nginx
    apiVersion: v1
    data:
      allow-snippet-annotations: "true"
      client-header-buffer-size: 32k  # 注意不是下划线
      client-max-body-size: 5m
      use-gzip: "true"
      gzip-level: "7"
      large-client-header-buffers: 4 32k
      proxy-connect-timeout: 11s
      proxy-read-timeout: 12s
      keep-alive: "75"   # 启用keep-alive，连接复用，提高QPS
      keep-alive-requests: "100"
      upstream-keepalive-connections: "10000"
      upstream-keepalive-requests: "100"
      upstream-keepalive-timeout: "60"
      disable-ipv6: "true"
      disable-ipv6-dns: "true"
      max-worker-connections: "65535"
      max-worker-open-files: "10240"
    kind: ConfigMap
    ......
    

修改完成后 Nginx 配置会自动重载生效，我们可以查看 `nginx.conf` 配置文件进行验证：
    
    
    ➜ kubectl exec -it ingress-nginx-controller-gc582 -n ingress-nginx -- cat /etc/nginx/nginx.conf |grep large_client_header_buffers
            large_client_header_buffers     4 32k;
    

由于我们这里是 Helm Chart 安装的，为了保证重新部署后配置还在，我们同样需要通过 Values 进行全局配置：
    
    
    # ci/daemonset-prod.yaml
    controller:
      config:
        allow-snippet-annotations: "true"
        client-header-buffer-size: 32k # 注意不是下划线
        client-max-body-size: 5m
        use-gzip: "true"
        gzip-level: "7"
        large-client-header-buffers: 4 32k
        proxy-connect-timeout: 11s
        proxy-read-timeout: 12s
        keep-alive: "75" # 启用keep-alive，连接复用，提高QPS
        keep-alive-requests: "100"
        upstream-keepalive-connections: "10000"
        upstream-keepalive-requests: "100"
        upstream-keepalive-timeout: "60"
        disable-ipv6: "true"
        disable-ipv6-dns: "true"
        max-worker-connections: "65535"
        max-worker-open-files: "10240"
    # 其他省略
    

此外往往我们还需要对 `ingress-nginx` 部署的节点进行性能优化，修改一些内核参数，使得适配 Nginx 的使用场景，一般我们是直接去修改节点上的内核参数，为了能够统一管理，我们可以使用 `initContainers` 来进行配置：
    
    
    initContainers:
    - command:
      - /bin/sh
      - -c
      - |
        mount -o remount rw /proc/sys
        sysctl -w net.core.somaxconn=65535  # 具体的配置视具体情况而定
        sysctl -w net.ipv4.tcp_tw_reuse=1
        sysctl -w net.ipv4.ip_local_port_range="1024 65535"
        sysctl -w fs.file-max=1048576
        sysctl -w fs.inotify.max_user_instances=16384
        sysctl -w fs.inotify.max_user_watches=524288
        sysctl -w fs.inotify.max_queued_events=16384
    image: busybox
    imagePullPolicy: IfNotPresent
    name: init-sysctl
    securityContext:
      capabilities:
        add:
        - SYS_ADMIN
        drop:
        - ALL
    ......
    

由于我们这里使用的是 Helm Chart 安装的 `ingress-nginx`，同样只需要去配置 Values 值即可，模板中提供了对 `initContainers` 的支持，配置如下所示：
    
    
    controller:
      # 其他省略，配置 initContainers
      extraInitContainers:
        - name: init-sysctl
          image: busybox
          securityContext:
            capabilities:
              add:
                - SYS_ADMIN
              drop:
                - ALL
          command:
            - /bin/sh
            - -c
            - |
              mount -o remount rw /proc/sys
              sysctl -w net.core.somaxconn=65535  # socket监听的backlog上限
              sysctl -w net.ipv4.tcp_tw_reuse=1  # 开启重用，允许将 TIME-WAIT sockets 重新用于新的TCP连接
              sysctl -w net.ipv4.ip_local_port_range="1024 65535"
              sysctl -w fs.file-max=1048576
              sysctl -w fs.inotify.max_user_instances=16384
              sysctl -w fs.inotify.max_user_watches=524288
              sysctl -w fs.inotify.max_queued_events=16384
    

同样重新部署即可：
    
    
    ➜ helm upgrade --install ingress-nginx . -f ./ci/daemonset-prod.yaml --namespace ingress-nginx
    

部署完成后通过 `initContainers` 就可以修改节点内核参数了，生产环境建议对节点内核参数进行相应的优化。
