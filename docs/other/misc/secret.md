# Secret

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/config/secret.md "编辑此页")

# Secret

敏感信息配置管理

前文我们学习 `ConfigMap` 的时候，我们说 `ConfigMap` 这个资源对象是 Kubernetes 当中非常重要的一个资源对象，一般情况下 ConfigMap 是用来存储一些非安全的配置信息，如果涉及到一些安全相关的数据的话用 ConfigMap 就非常不妥了，因为 ConfigMap 是明文存储的，这个时候我们就需要用到另外一个资源对象了：`Secret`，`Secret`用来保存敏感信息，例如密码、OAuth 令牌和 ssh key 等等，将这些信息放在 `Secret` 中比放在 Pod 的定义中或者 Docker 镜像中要更加安全和灵活。

`Secret` 主要使用的有以下三种类型：

  * `Opaque`：base64 编码格式的 Secret，用来存储密码、密钥等；但数据也可以通过 `base64 –decode` 解码得到原始数据，所有加密性很弱。
  * `kubernetes.io/dockercfg`: `~/.dockercfg` 文件的序列化形式
  * `kubernetes.io/dockerconfigjson`：用来存储私有`docker registry`的认证信息，`~/.docker/config.json` 文件的序列化形式
  * `kubernetes.io/service-account-token`：用于 `ServiceAccount`, ServiceAccount 创建时 Kubernetes 会默认创建一个对应的 Secret 对象，Pod 如果使用了 ServiceAccount，对应的 Secret 会自动挂载到 Pod 目录 `/run/secrets/kubernetes.io/serviceaccount` 中
  * `kubernetes.io/ssh-auth`：用于 SSH 身份认证的凭据
  * `kubernetes.io/basic-auth`：用于基本身份认证的凭据
  * `bootstrap.kubernetes.io/token`：用于节点接入集群的校验的 Secret



> 上面是 Secret 对象内置支持的几种类型，通过为 Secret 对象的 type 字段设置一个非空的字符串值，也可以定义并使用自己 Secret 类型。如果 type 值为空字符串，则被视为 Opaque 类型。Kubernetes 并不对类型的名称作任何限制，不过，如果要使用内置类型之一， 则你必须满足为该类型所定义的所有要求。

## Opaque Secret

`Secret` 资源包含2个键值对： `data` 和 `stringData`，`data` 字段用来存储 base64 编码的任意数据，提供 `stringData` 字段是为了方便，它允许 Secret 使用未编码的字符串。 `data` 和 `stringData` 的键必须由字母、数字、`-`，`_` 或 `.` 组成。

比如我们来创建一个用户名为 admin，密码为 admin321 的 `Secret` 对象，首先我们需要先把用户名和密码做 `base64` 编码：
    
    
    ➜  ~ echo -n "admin" | base64
    YWRtaW4=
    ➜  ~ echo -n "admin321" | base64
    YWRtaW4zMjE=
    

然后我们就可以利用上面编码过后的数据来编写一个 YAML 文件：(secret-demo.yaml)
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysecret
    type: Opaque
    data:
      username: YWRtaW4=
      password: YWRtaW4zMjE=
    

然后我们就可以使用 kubectl 命令来创建了：
    
    
    ➜  ~ kubectl apply -f secret-demo.yaml
    secret "mysecret" created
    

利用`get secret`命令查看：
    
    
    ➜  ~ kubectl get secret
    NAME                  TYPE                                  DATA      AGE
    default-token-n9w2d   kubernetes.io/service-account-token   3         33d
    mysecret              Opaque                                2         40s
    

其中 `default-token-n9w2d` 为创建集群时默认创建的 Secret，被 `serviceacount/default` 引用。我们可以使用 `describe` 命令查看详情：
    
    
    ➜  ~ kubectl describe secret mysecret
    Name:         mysecret
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>
    
    Type:  Opaque
    
    Data
    ====
    password:  8 bytes
    username:  5 bytes
    

我们可以看到利用 describe 命令查看到的 Data 没有直接显示出来，如果想看到 Data 里面的详细信息，同样我们可以输出成YAML 文件进行查看：
    
    
    ➜  ~ kubectl get secret mysecret -o yaml
    apiVersion: v1
    data:
      password: YWRtaW4zMjE=
      username: YWRtaW4=
    kind: Secret
    metadata:
      creationTimestamp: 2018-06-19T15:27:06Z
      name: mysecret
      namespace: default
      resourceVersion: "3694084"
      selfLink: /api/v1/namespaces/default/secrets/mysecret
      uid: 39c139f5-73d5-11e8-a101-525400db4df7
    type: Opaque
    

对于某些场景，你可能希望使用 `stringData` 字段，这字段可以将一个非 base64 编码的字符串直接放入 Secret 中， 当创建或更新该 Secret 时，此字段将被编码。

比如当我们部署应用时，使用 Secret 存储配置文件， 你希望在部署过程中，填入部分内容到该配置文件。例如，如果你的应用程序使用以下配置文件:
    
    
    apiUrl: "https://my.api.com/api/v1"
    username: "<user>"
    password: "<password>"
    

那么我们就可以使用以下定义将其存储在 Secret 中:
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysecret
    type: Opaque
    stringData:
      config.yaml: |
        apiUrl: "https://my.api.com/api/v1"
        username: <user>
        password: <password>
    

比如我们直接创建上面的对象后重新获取对象的话 `config.yaml` 的值会被编码：
    
    
    ➜  ~ kubectl get secret mysecret -o yaml
    apiVersion: v1
    data:
      config.yaml: YXBpVXJsOiAiaHR0cHM6Ly9teS5hcGkuY29tL2FwaS92MSIKdXNlcm5hbWU6IDx1c2VyPgpwYXNzd29yZDogPHBhc3N3b3JkPgo=
    kind: Secret
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"v1","kind":"Secret","metadata":{"annotations":{},"name":"mysecret","namespace":"default"},"stringData":{"config.yaml":"apiUrl: \"https://my.api.com/api/v1\"\nusername: \u003cuser\u003e\npassword: \u003cpassword\u003e\n"},"type":"Opaque"}
      creationTimestamp: "2021-11-21T10:42:25Z"
      managedFields:
      - apiVersion: v1
        fieldsType: FieldsV1
        fieldsV1:
          f:data:
            .: {}
            f:config.yaml: {}
          f:metadata:
            f:annotations:
              .: {}
              f:kubectl.kubernetes.io/last-applied-configuration: {}
          f:type: {}
        manager: kubectl
        operation: Update
        time: "2021-11-21T10:42:25Z"
      name: mysecret
      namespace: default
      resourceVersion: "857340"
      uid: 5a28d296-5f53-4e4c-92f3-c1d7c952ace2
    type: Opaque
    

创建好 `Secret`对象后，有两种方式来使用它：

  * 以环境变量的形式
  * 以Volume的形式挂载



### 环境变量

首先我们来测试下环境变量的方式，同样的，我们来使用一个简单的 busybox 镜像来测试下:(secret1-pod.yaml)
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: secret1-pod
    spec:
      containers:
      - name: secret1
        image: busybox
        command: [ "/bin/sh", "-c", "env" ]
        env:
        - name: USERNAME
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: password
    

主要需要注意的是上面环境变量中定义的 `secretKeyRef` 字段，和我们前文的 `configMapKeyRef` 类似，一个是从 `Secret` 对象中获取，一个是从 `ConfigMap` 对象中获取，创建上面的 Pod：
    
    
    ➜  ~ kubectl create -f secret1-pod.yaml
    pod "secret1-pod" created
    

然后我们查看Pod的日志输出：
    
    
    ➜  ~ kubectl logs secret1-pod
    ...
    USERNAME=admin
    PASSWORD=admin321
    ...
    

可以看到有 USERNAME 和 PASSWORD 两个环境变量输出出来。

### Volume 挂载

同样的我们用一个 Pod 来验证下 `Volume` 挂载，创建一个 Pod 文件：(secret2-pod.yaml)
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: secret2-pod
    spec:
      containers:
      - name: secret2
        image: busybox
        command: ["/bin/sh", "-c", "ls /etc/secrets"]
        volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
      volumes:
      - name: secrets
        secret:
         secretName: mysecret
    

创建 Pod，然后查看输出日志：
    
    
    ➜  ~ kubectl create -f secret-pod2.yaml
    pod "secret2-pod" created
    ➜  ~ kubectl logs secret2-pod
    password
    username
    

可以看到 Secret 把两个 key 挂载成了两个对应的文件。当然如果想要挂载到指定的文件上面，是不是也可以使用上一节课的方法：在 `secretName` 下面添加 `items` 指定 `key` 和 `path`，这个大家可以参考上节课 `ConfigMap` 中的方法去测试下。

## kubernetes.io/dockerconfigjson

除了上面的 `Opaque` 这种类型外，我们还可以来创建用户 `docker registry` 认证的 `Secret`，直接使用``kubectl create` 命令创建即可，如下：
    
    
    ➜  ~ kubectl create secret docker-registry myregistry --docker-server=DOCKER_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
    secret "myregistry" created
    

除了上面这种方法之外，我们也可以通过指定文件的方式来创建镜像仓库认证信息，需要注意对应的 `KEY` 和 `TYPE`：
    
    
    kubectl create secret generic myregistry --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson
    

然后查看 Secret 列表：
    
    
    ➜  ~ kubectl get secret
    NAME                  TYPE                                  DATA      AGE
    default-token-n9w2d   kubernetes.io/service-account-token   3         33d
    myregistry            kubernetes.io/dockerconfigjson        1         15s
    mysecret              Opaque                                2         34m
    

注意看上面的 TYPE 类型，myregistry 对应的是 `kubernetes.io/dockerconfigjson`，同样的可以使用 describe 命令来查看详细信息：
    
    
    ➜  ~ kubectl describe secret myregistry
    Name:         myregistry
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>
    
    Type:  kubernetes.io/dockerconfigjson
    
    Data
    ====
    .dockerconfigjson:  152 bytes
    

同样的可以看到 Data 区域没有直接展示出来，如果想查看的话可以使用 `-o yaml` 来输出展示出来：
    
    
    ➜  ~ kubectl get secret myregistry -o yaml
    apiVersion: v1
    data:
      .dockerconfigjson: eyJhdXRocyI6eyJET0NLRVJfU0VSVkVSIjp7InVzZXJuYW1lIjoiRE9DS0VSX1VTRVIiLCJwYXNzd29yZCI6IkRPQ0tFUl9QQVNTV09SRCIsImVtYWlsIjoiRE9DS0VSX0VNQUlMIiwiYXV0aCI6IlJFOURTMFZTWDFWVFJWSTZSRTlEUzBWU1gxQkJVMU5YVDFKRSJ9fX0=
    kind: Secret
    metadata:
      creationTimestamp: 2018-06-19T16:01:05Z
      name: myregistry
      namespace: default
      resourceVersion: "3696966"
      selfLink: /api/v1/namespaces/default/secrets/myregistry
      uid: f91db707-73d9-11e8-a101-525400db4df7
    type: kubernetes.io/dockerconfigjson
    

可以把上面的 `data.dockerconfigjson` 下面的数据做一个 `base64` 解码，看看里面的数据是怎样的呢？
    
    
    ➜  ~ echo eyJhdXRocyI6eyJET0NLRVJfU0VSVkVSIjp7InVzZXJuYW1lIjoiRE9DS0VSX1VTRVIiLCJwYXNzd29yZCI6IkRPQ0tFUl9QQVNTV09SRCIsImVtYWlsIjoiRE9DS0VSX0VNQUlMIiwiYXV0aCI6IlJFOURTMFZTWDFWVFJWSTZSRTlEUzBWU1gxQkJVMU5YVDFKRSJ9fX0= | base64 -d
    {"auths":{"DOCKER_SERVER":{"username":"DOCKER_USER","password":"DOCKER_PASSWORD","email":"DOCKER_EMAIL","auth":"RE9DS0VSX1VTRVI6RE9DS0VSX1BBU1NXT1JE"}}}
    

如果我们需要拉取私有仓库中的 Docker 镜像的话就需要使用到上面的 myregistry 这个 `Secret`：
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: foo
    spec:
      containers:
      - name: foo
        image: 192.168.1.100:5000/test:v1
      imagePullSecrets:
      - name: myregistry
    

imagePullSecrets

`ImagePullSecrets` 与 `Secrets` 不同，因为 `Secrets` 可以挂载到 Pod 中，但是 `ImagePullSecrets` 只能由 Kubelet 访问。

我们需要拉取私有仓库镜像 `192.168.1.100:5000/test:v1`，我们就需要针对该私有仓库来创建一个如上的 `Secret`，然后在 Pod 中指定 `imagePullSecrets`。

除了设置 `Pod.spec.imagePullSecrets` 这种方式来获取私有镜像之外，我们还可以通过在 `ServiceAccount` 中设置 `imagePullSecrets`，然后就会自动为使用该 SA 的 Pod 注入 `imagePullSecrets` 信息：
    
    
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      creationTimestamp: "2019-11-08T12:00:04Z"
      name: default
      namespace: default
      resourceVersion: "332"
      selfLink: /api/v1/namespaces/default/serviceaccounts/default
      uid: cc37a719-c4fe-4ebf-92da-e92c3e24d5d0
    secrets:
    - name: default-token-5tsh4
    imagePullSecrets:
    - name: myregistry
    

## kubernetes.io/basic-auth

该类型用来存放用于基本身份认证所需的凭据信息，使用这种 Secret 类型时，Secret 的 data 字段（不一定）必须包含以下两个键（相当于是约定俗成的一个规定）：

  * `username`: 用于身份认证的用户名
  * `password`: 用于身份认证的密码或令牌



以上两个键的键值都是 `base64` 编码的字符串。 然你也可以在创建 Secret 时使用 `stringData` 字段来提供明文形式的内容。下面的 YAML 是基本身份认证 Secret 的一个示例清单：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: secret-basic-auth
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: admin321
    

提供基本身份认证类型的 Secret 仅仅是出于用户方便性考虑，我们也可以使用 Opaque 类型来保存用于基本身份认证的凭据，不过使用内置的 Secret 类型的有助于对凭据格式进行统一处理。

## kubernetes.io/ssh-auth

该类型用来存放 SSH 身份认证中所需要的凭据，使用这种 Secret 类型时，你就不一定必须在其 data（或 stringData）字段中提供一个 `ssh-privatekey` 键值对，作为要使用的 SSH 凭据。

如下所示是一个 SSH 身份认证 Secret 的配置示例：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: secret-ssh-auth
    type: kubernetes.io/ssh-auth
    data:
      ssh-privatekey: |
              MIIEpQIBAAKCAQEAulqb/Y ...
    

同样提供 SSH 身份认证类型的 Secret 也仅仅是出于用户方便性考虑，我们也可以使用 Opaque 类型来保存用于 SSH 身份认证的凭据，只是使用内置的 Secret 类型的有助于对凭据格式进行统一处理。

## kubernetes.io/tls

该类型用来存放证书及其相关密钥（通常用在 TLS 场合）。此类数据主要提供给 Ingress 资源，用以校验 TLS 链接，当使用此类型的 Secret 时，Secret 配置中的 data （或 stringData）字段必须包含 `tls.key` 和 `tls.crt`主键。下面的 YAML 包含一个 TLS Secret 的配置示例：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      name: secret-tls
    type: kubernetes.io/tls
    data:
      tls.crt: |
            MIIC2DCCAcCgAwIBAgIBATANBgkqh ...
      tls.key: |
            MIIEpgIBAAKCAQEA7yn3bRHQ5FHMQ ...
    

提供 TLS 类型的 Secret 仅仅是出于用户方便性考虑，我们也可以使用 Opaque 类型来保存用于 TLS 服务器与/或客户端的凭据。不过，使用内置的 Secret 类型的有助于对凭据格式进行统一化处理。当使用 kubectl 来创建 TLS Secret 时，我们可以像下面的例子一样使用 tls 子命令：
    
    
    ➜  ~ kubectl create secret tls my-tls-secret \
      --cert=path/to/cert/file \
      --key=path/to/key/file
    

需要注意的是用于 `--cert` 的公钥证书必须是 `.PEM` 编码的 （Base64 编码的 DER 格式），且与 `--key` 所给定的私钥匹配，私钥必须是通常所说的 PEM 私钥格式，且未加密。对这两个文件而言，PEM 格式数据的第一行和最后一行（例如，证书所对应的 `--------BEGIN CERTIFICATE-----` 和 `-------END CERTIFICATE----`）都不会包含在其中。

## kubernetes.io/service-account-token

另外一种 `Secret` 类型就是 `kubernetes.io/service-account-token`，用于被 `ServiceAccount` 引用。`ServiceAccout` 创建时 Kubernetes 会默认创建对应的 `Secret`，如下所示我们随意创建一个 Pod：
    
    
    ➜  ~ kubectl run secret-pod3 --image nginx:1.7.9
    deployment.apps "secret-pod3" created
    ➜  ~ kubectl get pods
    NAME                           READY     STATUS    RESTARTS   AGE
    ...
    secret-pod3-78c8c76db8-7zmqm   1/1       Running   0          13s
    ...
    

我们可以直接查看这个 Pod 的详细信息：
    
    
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: kube-api-access-lvhfb
          readOnly: true
      ......
      serviceAccount: default
      serviceAccountName: default
      volumes:
      - name: kube-api-access-lvhfb
        projected:
          defaultMode: 420
          sources:
          - serviceAccountToken:
              expirationSeconds: 3607
              path: token
          - configMap:
              items:
              - key: ca.crt
                path: ca.crt
              name: kube-root-ca.crt
          - downwardAPI:
              items:
              - fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
                path: namespace
    

当创建 Pod 的时候，如果没有指定 ServiceAccount，Pod 则会使用命名空间中名为 default 的 ServiceAccount，上面我们可以看到 `spec.serviceAccountName` 字段已经被自动设置了。

可以看到这里通过一个 `projected` 类型的 Volume 挂载到了容器的 `/var/run/secrets/kubernetes.io/serviceaccount` 的目录中，`projected` 类型的 Volume 可以同时挂载多个来源的数据，这里我们挂载了一个 downwardAPI 来获取 namespace，通过 ConfigMap 来获取 `ca.crt` 证书，然后还有一个 `serviceAccountToken` 类型的数据源。

在之前的版本（v1.20）中，是直接将 `default`（自动创建的）的 `ServiceAccount` 对应的 Secret 对象通过 Volume 挂载到了容器的 `/var/run/secrets/kubernetes.io/serviceaccount` 的目录中的，现在的版本提供了更多的配置选项，比如上面我们配置了 `expirationSeconds` 和 `path` 两个属性。

前面我们也提到了默认情况下当前 namespace 下面的 Pod 会默认使用 `default` 这个 ServiceAccount，对应的 `Secret` 会自动挂载到 Pod 的 `/var/run/secrets/kubernetes.io/serviceaccount/` 目录中，这样我们就可以在 Pod 里面获取到用于身份认证的信息了。

我们可以使用自动挂载给 Pod 的 ServiceAccount 凭据访问 API，我们也可以通过在 ServiceAccount 上设置 `automountServiceAccountToken: false` 来实现不给 ServiceAccount 自动挂载 API 凭据：
    
    
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: build-robot
    automountServiceAccountToken: false
    ...
    

此外也可以选择不给特定 Pod 自动挂载 API 凭据：
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-pod
    spec:
      serviceAccountName: build-robot
      automountServiceAccountToken: false
      ...
    

如果 Pod 和 ServiceAccount 都指定了 `automountServiceAccountToken` 值，则 Pod 的 spec 优先于 ServiceAccount。

### ServiceAccount Token 投影

`ServiceAccount` 是 Pod 和集群 apiserver 通讯的访问凭证，传统方式下，在 Pod 中使用 ServiceAccount 可能会遇到如下的安全挑战：

  * `ServiceAccount` 中的 `JSON Web Token (JWT)` 没有绑定 audience 身份，因此所有 ServiceAccount 的使用者都可以彼此扮演，存在伪装攻击的可能
  * 传统方式下每一个 ServiceAccount 都需要存储在一个对应的 Secret 中，并且会以文件形式存储在对应的应用节点上，而集群的系统组件在运行过程中也会使用到一些权限很高的 ServiceAccount，其增大了集群管控平面的攻击面，攻击者可以通过获取这些管控组件使用的 ServiceAccount 非法提权
  * ServiceAccount 中的 JWT token 没有设置过期时间，当上述 ServiceAccount 泄露情况发生时，只能通过轮转 ServiceAccount 的签发私钥来进行防范
  * 每一个 ServiceAccount 都需要创建一个与之对应的 Secret，在大规模的应用部署下存在弹性和容量风险



为解决这个问题 Kubernetes 提供了 ServiceAccount Token 投影特性用于增强 ServiceAccount 的安全性，ServiceAccount 令牌卷投影可使 Pod 支持以卷投影的形式将 ServiceAccount 挂载到容器中从而避免了对 Secret 的依赖。

通过 ServiceAccount 令牌卷投影可用于工作负载的 ServiceAccount 令牌是受时间限制，受 audience 约束的,并且不与 Secret 对象关联。如果删除了 Pod 或删除了 ServiceAccount，则这些令牌将无效，从而可以防止任何误用，Kubelet 还会在令牌即将到期时自动旋转令牌，另外，还可以配置希望此令牌可用的路径。

为了启用令牌请求投射（此功能在 Kubernetes 1.12 中引入，Kubernetes v1.20 已经稳定版本），你必须为 `kube-apiserver` 设置以下命令行参数，通过 kubeadm 安装的集群已经默认配置了：
    
    
    --service-account-issuer  # serviceaccount token 中的签发身份，即token payload中的iss字段。
    --service-account-key-file # token 私钥文件路径
    --service-account-signing-key-file  # token 签名私钥文件路径
    --api-audiences (可选参数)  # 合法的请求token身份，用于apiserver服务端认证请求token是否合法。
    

配置完成后就可以指定令牌的所需属性，例如身份和有效时间，这些属性在默认 ServiceAccount 令牌上无法配置。当删除 Pod 或 ServiceAccount 时，ServiceAccount 令牌也将对 API 无效。

我们可以使用名为 `ServiceAccountToken` 的 `ProjectedVolume` 类型在 PodSpec 上配置此功能，比如要向 Pod 提供具有 "vault" 用户以及两个小时有效期的令牌，可以在 PodSpec 中配置以下内容：

例如当 Pod 中需要使用 audience 为 vault 并且有效期为2个小时的 ServiceAccount 时，我们可以使用以下模板配置 PodSpec 来使用 ServiceAccount 令牌卷投影。
    
    
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: build-robot
    
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - mountPath: /var/run/secrets/tokens
          name: vault-token
      serviceAccountName: build-robot
      volumes:
      - name: vault-token
        projected:
          sources:
          - serviceAccountToken:
              path: vault-token
              expirationSeconds: 7200
              audience: vault
    

kubelet 组件会替 Pod 请求令牌并将其保存起来，通过将令牌存储到一个可配置的路径使之在 Pod 内可用，并在令牌快要到期的时候刷新它。 kubelet 会在令牌存在期达到其 TTL 的 80% 的时候或者令牌生命期超过 24 小时的时候主动轮换它。应用程序负责在令牌被轮换时重新加载其内容。对于大多数使用场景而言，周期性地（例如，每隔 5 分钟）重新加载就足够了。

## 其他特性

如果某个容器已经在通过环境变量使用某 Secret，对该 Secret 的更新不会被容器马上看见，除非容器被重启，当然我们可以使用一些第三方的解决方案在 Secret 发生变化时触发容器重启。

在 Kubernetes v1.21 版本提供了不可变的 Secret 和 ConfigMap 的可选配置[stable]，我们可以设置 Secret 和 ConfigMap 为不可变的，对于大量使用 Secret 或者 ConfigMap 的集群（比如有成千上万各不相同的 Secret 供 Pod 挂载）时，禁止变更它们的数据有很多好处：

  * 可以防止意外更新导致应用程序中断
  * 通过将 Secret 标记为不可变来关闭 `kube-apiserver` 对其的 watch 操作，从而显著降低 `kube-apiserver` 的负载，提升集群性能



这个特性通过可以通过 `ImmutableEmphemeralVolumes` 特性门来进行开启，从 v1.19 开始默认启用，我们可以通过将 Secret 的 `immutable` 字段设置为 true 创建不可更改的 Secret。 例如：
    
    
    apiVersion: v1
    kind: Secret
    metadata:
      ...
    data:
      ...
    immutable: true  # 标记为不可变
    

> 一旦一个 Secret 或 ConfigMap 被标记为不可更改，撤销此操作或者更改 data 字段的内容都是不允许的，只能删除并重新创建这个 Secret。现有的 Pod 将维持对已删除 Secret 的挂载点，所以我们也是建议重新创建这些 Pod。

## Secret vs ConfigMap

最后我们来对比下 `Secret` 和 `ConfigMap`这两种资源对象的异同点：

### 相同点

  * key/value的形式
  * 属于某个特定的命名空间
  * 可以导出到环境变量
  * 可以通过目录/文件形式挂载
  * 通过 volume 挂载的配置信息均可热更新



### 不同点

  * Secret 可以被 ServerAccount 关联
  * Secret 可以存储 `docker register` 的鉴权信息，用在 `ImagePullSecret` 参数中，用于拉取私有仓库的镜像
  * Secret 支持 `Base64` 加密
  * Secret 分为 `kubernetes.io/service-account-token`、`kubernetes.io/dockerconfigjson`、`Opaque` 三种类型，而 `Configmap` 不区分类型



使用注意

同样 Secret 文件大小限制为 `1MB`（ETCD 的要求）；Secret 虽然采用 `Base64` 编码，但是我们还是可以很方便解码获取到原始信息，所以对于非常重要的数据还是需要慎重考虑，可以考虑使用 [Vault](https://www.vaultproject.io/) 来进行加密管理。
