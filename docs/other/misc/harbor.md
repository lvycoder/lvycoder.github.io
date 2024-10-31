# Harbor

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/devops/harbor.md "编辑此页")

# Harbor

Harbor 是一个 CNCF 基金会托管的开源的可信的云原生 docker registry 项目，可以用于存储、签名、扫描镜像内容，Harbor 通过添加一些常用的功能如安全性、身份权限管理等来扩展 docker registry 项目，此外还支持在 registry 之间复制镜像，还提供更加高级的安全功能，如用户管理、访问控制和活动审计等，在新版本中还添加了 Helm 仓库托管的支持。

Harbor 最核心的功能就是给 `docker registry` 添加上一层权限保护的功能，要实现这个功能，就需要我们在使用 docker login、pull、push 等命令的时候进行拦截，先进行一些权限相关的校验，再进行操作，其实这一系列的操作 `docker registry v2` 就已经为我们提供了支持，v2 集成了一个安全认证的功能，将安全认证暴露给外部服务，让外部服务去实现。

## Harbor 认证原理

上面我们说了 `docker registry v2` 将安全认证暴露给了外部服务使用，那么是怎样暴露的呢？我们在命令行中输入 `docker login https://registry.qikqiak.com` 为例来为大家说明下认证流程：

  1. docker client 接收到用户输入的 docker login 命令，将命令转化为调用 engine api 的 RegistryLogin 方法
  2. 在 RegistryLogin 方法中通过 http 调用 registry 服务中的 auth 方法
  3. 因为我们这里使用的是 v2 版本的服务，所以会调用 loginV2 方法，在 loginV2 方法中会进行 /v2/ 接口调用，该接口会对请求进行认证
  4. 此时的请求中并没有包含 token 信息，认证会失败，返回 401 错误，同时会在 header 中返回去哪里请求认证的服务器地址
  5. registry client 端收到上面的返回结果后，便会去返回的认证服务器那里进行认证请求，向认证服务器发送的请求的 header 中包含有加密的用户名和密码
  6. 认证服务器从 header 中获取到加密的用户名和密码，这个时候就可以结合实际的认证系统进行认证了，比如从数据库中查询用户认证信息或者对接 ldap 服务进行认证校验
  7. 认证成功后，会返回一个 token 信息，client 端会拿着返回的 token 再次向 registry 服务发送请求，这次需要带上得到的 token，请求验证成功，返回状态码就是 200 了
  8. docker client 端接收到返回的 200 状态码，说明操作成功，在控制台上打印 Login Succeeded 的信息 至此，整个登录过程完成，整个过程可以用下面的流程图来说明：



![docker login](https://picdn.youdianzhishi.com/images/20200512145015.png)

要完成上面的登录认证过程有两个关键点需要注意：怎样让 registry 服务知道服务认证地址？我们自己提供的认证服务生成的 token 为什么 registry 就能够识别？

对于第一个问题，比较好解决，registry 服务本身就提供了一个配置文件，可以在启动 registry 服务的配置文件中指定上认证服务地址即可，其中有如下这样的一段配置信息：
    
    
    ......
    auth:
      token:
        realm: token-realm
        service: token-service
        issuer: registry-token-issuer
        rootcertbundle: /root/certs/bundle
    ......
    

其中 realm 就可以用来指定一个认证服务的地址，下面我们可以看到 Harbor 中该配置的内容。

> 关于 registry 的配置，可以参考官方文档：<https://docs.docker.com/registry/configuration/>

第二个问题，就是 registry 怎么能够识别我们返回的 token 文件？如果按照 registry 的要求生成一个 token，是不是 registry 就可以识别了？所以我们需要在我们的认证服务器中按照 registry 的要求生成 token，而不是随便乱生成。那么要怎么生成呢？我们可以在 docker registry 的源码中可以看到 token 是通过 `JWT（JSON Web Token）` 来实现的，所以我们按照要求生成一个 JWT 的 token 就可以了。

对 golang 熟悉的同学可以去 clone 下 Harbor 的代码查看下，Harbor 采用 beego 这个 web 开发框架，源码阅读起来不是特别困难。我们可以很容易的看到 Harbor 中关于上面我们讲解的认证服务部分的实现方法。

![Harbor 组件](https://picdn.youdianzhishi.com/images/20210529175458.png)

## 安装

Harbor 涉及的组件比较多，我们可以使用 Helm 来安装一个高可用版本的 Harbor，也符合生产环境的部署方式。在安装高可用的版本之前，我们需要如下先决条件：

  * Kubernetes 集群 1.10+ 版本
  * Helm 2.8.0+ 版本
  * 高可用的 Ingress 控制器
  * 高可用的 PostgreSQL 9.6+（Harbor 不进行数据库 HA 的部署）
  * 高可用的 Redis 服务（Harbor 不处理）
  * 可以跨节点或外部对象存储共享的 PVC



Harbor 的大部分组件都是无状态的，所以我们可以简单增加 Pod 的副本，保证组件尽量分布到多个节点上即可，在存储层，需要我们自行提供高可用的 PostgreSQL、Redis 集群来存储应用数据，以及存储镜像和 Helm Chart 的 PVC 或对象存储。

![Harbor 架构](https://picdn.youdianzhishi.com/images/20210529145740.png)

首先添加 Chart 仓库地址：
    
    
    # 添加 Chart 仓库
    $ helm repo add harbor https://helm.goharbor.io
    # 更新
    $ helm repo update
    # 拉取1.9.2版本并解压
    $ helm pull harbor/harbor --untar --version 1.9.2
    

在安装 Harbor 的时候有很多可以配置的参数，可以在 [harbor-helm](https://github.com/goharbor/harbor-helm) 项目上进行查看，在安装的时候我们可以通过 `--set` 指定参数或者 `values.yaml` 直接编辑 Values 文件即可：

  * **Ingress** 配置通过 `expose.ingress.hosts.core` 和 `expose.ingress.hosts.notary`
  * **外部 URL** 通过配置 `externalURL`
  * **外部 PostgreSQL** 通过配置 `database.type` 为 `external`，然后补充上 `database.external` 的信息。需要我们手动创建 3 个空的数据：`Harbor core`、`Notary server` 以及 `Notary signer`，Harbor 会在启动时自动创建表结构
  * **外部 Redis** 通过配置 `redis.type` 为 `external`，并填充 `redis.external` 部分的信息。Harbor 在 2.1.0 版本中引入了 redis 的 `Sentinel` 模式，你可以通过配置 `sentinel_master_set` 来开启，host 地址可以设置为 `<host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3>`。还可以参考文档[https://community.pivotal.io/s/article/How-to-setup-HAProxy-and-Redis-Sentinel-for-automatic-failover-between-Redis-Master-and-Slave-servers](https://community.pivotal.io/s/article/How-to-setup-HAProxy-and-Redis-Sentinel-for-automatic-failover-between-Redis-Master-and-Slave-servers?language=en_US) 在 Redis 前面配置一个 HAProxy 来暴露单个入口点。
  * **存储** ，默认情况下需要一个默认的 `StorageClass` 在 K8S 集群中来自动生成 PV，用来存储镜像、Charts 和任务日志。如果你想指定 `StorageClass`，可以通过 `persistence.persistentVolumeClaim.registry.storageClass`、`persistence.persistentVolumeClaim.chartmuseum.storageClass` 以及 `persistence.persistentVolumeClaim.jobservice.storageClass` 进行配置，另外还需要将 accessMode 设置为 `ReadWriteMany`，确保 PV 可以跨不同节点进行共享存储。此外我们还可以通过指定存在的 PVCs 来存储数据，可以通过 `existingClaim` 进行配置。如果你没有可以跨节点共享的 PVC，你可以使用外部存储来存储镜像和 Chart（外部存储支持：azure，gcs，s3 swift 和 oss），并将任务日志存储在数据库中。将设置为 `persistence.imageChartStorage.type` 为你要使用的值并填充相应部分并设置 `jobservice.jobLogger` 为 `database`
  * **副本** ：通过设置 `portal.replicas`，`core.replicas`，`jobservice.replicas`，`registry.replicas`，`chartmuseum.replicas`，`notary.server.replicas` 和 `notary.signer.replicas` 为 n（n> = 2）



比如这里我们将主域名配置为 `harbor.k8s.local`，通过一个 `nfs-client` 的 StorageClass 来提供存储，又因为前面我们在安装 GitLab 的时候就已经单独安装了 postgresql 和 reids 两个数据库，所以我们也可以配置 Harbor 使用这两个外置的数据库，这样可以降低资源的使用（我们可以认为这两个数据库都是 HA 模式）。但是使用外置的数据库我们需要提前手动创建数据库，比如我们这里使用的 GitLab 提供的数据库，则进入该 Pod 创建 `harbor`、`notary_server`、`notary_signer` 这 3 个数据库：
    
    
    $ kubectl get pods -n kube-ops -l name=postgresql
    NAME                          READY   STATUS    RESTARTS   AGE
    postgresql-75b8447fb5-th6bw   1/1     Running   1          2d
    $ kubectl exec -it postgresql-75b8447fb5-th6bw /bin/bash -n kube-ops
    kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
    root@postgresql-75b8447fb5-th6bw:/var/lib/postgresql# sudo su - postgres
    postgres@postgresql-75b8447fb5-th6bw:~$ psql
    psql (12.3 (Ubuntu 12.3-1.pgdg18.04+1))
    Type "help" for help.
    
    postgres=# CREATE DATABASE harbor OWNER postgres;
    CREATE DATABASE
    postgres=# GRANT ALL PRIVILEGES ON DATABASE harbor to postgres;
    GRANT
    postgres=# GRANT ALL PRIVILEGES ON DATABASE harbor to gitlab;
    GRANT
    # Todo: 用同样的方式创建其他两个数据库：notary_server、notary_signer
    ......
    postgres-# \q  # 退出
    

数据库准备过后，就可以使用我们自己定制的 values 文件来进行安装了，完整的定制的 values 文件如下所示：
    
    
    # values-prod.yaml
    externalURL: https://harbor.k8s.local
    harborAdminPassword: Harbor12345
    logLevel: debug
    
    expose:
      type: ingress
      tls:
        enabled: true
      ingress:
        className: nginx # 指定 ingress class
        hosts:
          core: harbor.k8s.local
          notary: notary.k8s.local
    
    persistence:
      enabled: true
      resourcePolicy: "keep"
      persistentVolumeClaim:
        registry:
          # 如果需要做高可用，多个副本的组件则需要使用支持 ReadWriteMany 的后端
          # 这里我们使用nfs，生产环境不建议使用nfs
          storageClass: "nfs-client"
          # 如果是高可用的，多个副本组件需要使用 ReadWriteMany，默认为 ReadWriteOnce
          accessMode: ReadWriteMany
          size: 5Gi
        chartmuseum:
          storageClass: "nfs-client"
          accessMode: ReadWriteMany
          size: 5Gi
        jobservice:
          storageClass: "nfs-client"
          accessMode: ReadWriteMany
          size: 1Gi
        trivy:
          storageClass: "nfs-client"
          accessMode: ReadWriteMany
          size: 2Gi
    
    database:
      type: external
      external:
        host: "postgresql.kube-ops.svc.cluster.local"
        port: "5432"
        username: "gitlab"
        password: "passw0rd"
        coreDatabase: "harbor"
        notaryServerDatabase: "notary_server"
        notarySignerDatabase: "notary_signer"
    
    redis:
      type: external
      external:
        addr: "redis.kube-ops.svc.cluster.local:6379"
    
    # 默认为一个副本，如果要做高可用，只需要设置为 replicas >= 2 即可
    portal:
      replicas: 1
    core:
      replicas: 1
    jobservice:
      replicas: 1
    registry:
      replicas: 1
    chartmuseum:
      replicas: 1
    trivy:
      replicas: 1
    notary:
      server:
        replicas: 1
      signer:
        replicas: 1
    

这些配置信息都是根据 Harbor 的 Chart 包默认的 values 值进行覆盖的，现在我们直接安装即可：
    
    
    $ cd harbor
    $ helm upgrade --install harbor . -f values-prod.yaml -n kube-ops
    Release "harbor" does not exist. Installing it now.
    NAME: harbor
    LAST DEPLOYED: Thu Jul  7 17:31:43 2022
    NAMESPACE: kube-ops
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Please wait for several minutes for Harbor deployment to complete.
    Then you should be able to visit the Harbor portal at https://harbor.k8s.local
    For more details, please visit https://github.com/goharbor/harbor
    

正常情况下隔一会儿就可以安装成功了：
    
    
    $ helm ls -n kube-ops
    NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
    harbor  kube-ops        1               2022-07-07 17:31:43.083547 +0800 CST    deployed        harbor-1.9.2    2.5.2
    $ kubectl get pods -n kube-ops -l app=harbor
    NAME                                    READY   STATUS    RESTARTS      AGE
    harbor-chartmuseum-544ddbcb64-nvk7w     1/1     Running   0             30m
    harbor-core-7fd9964685-lqqw2            1/1     Running   0             30m
    harbor-jobservice-6dbd89c59-vvzx5       1/1     Running   0             30m
    harbor-notary-server-764b8859bf-82f5q   1/1     Running   0             30m
    harbor-notary-signer-869d9bf585-kbwwg   1/1     Running   0             30m
    harbor-portal-74db6bb688-2w79p          1/1     Running   0             35m
    harbor-registry-695db89bfd-v9wwt        2/2     Running   0             30m
    harbor-trivy-0                          1/1     Running   0             35m
    

安装完成后，我们就可以将域名 `harbor.k8s.local` 解析到 Ingress Controller 流量入口点，然后就可以通过该域名在浏览器中访问了：
    
    
    $ kubectl get ingress -n kube-ops
    NAME                                      CLASS         HOSTS                                               ADDRESS         PORTS     AGE
    harbor-ingress                            nginx         harbor.k8s.local                                                    80, 443   12s
    harbor-ingress-notary                     nginx         notary.k8s.local                                                    80, 443   12s
    

用户名使用默认的 admin，密码则是上面配置的默认 `Harbor12345`，需要注意的是要使用 https 进行访问（默认也会跳转到 https），否则登录可能提示用户名或密码错误：

![harbor login](https://picdn.youdianzhishi.com/images/1657187588452.png)

登录过后即可进入 Harbor 的 Dashboard 页面：

![harbor dashboard](https://picdn.youdianzhishi.com/images/1657187621999.png)

我们可以看到有很多功能，默认情况下会有一个名叫 `library` 的项目，该项目默认是公开访问权限的，进入项目可以看到里面还有 `Helm Chart` 包的管理，可以手动在这里上传，也可以对该项目里面的镜像进行一些其他配置。

## 推送镜像

接下来我们来测试下如何在 containerd 中使用 Harbor 镜像仓库。

首先我们需要将私有镜像仓库配置到 containerd 中去，修改 containerd 的配置文件 `/etc/containerd/config.toml`：
    
    
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://bqr1dr1n.mirror.aliyuncs.com"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.k8s.local".tls]
          insecure_skip_verify = true
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.k8s.local".auth]
          username = "admin"
          password = "Harbor12345"
    

在 `plugins."io.containerd.grpc.v1.cri".registry.configs` 下面添加对应 `harbor.k8s.local` 的配置信息，`insecure_skip_verify = true` 表示跳过安全校验，然后通过 `plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.k8s.local".auth` 配置 Harbor 镜像仓库的用户名和密码。

配置完成后重启 containerd：
    
    
    $ systemctl restart containerd
    

现在我们使用 `nerdctl` 来进行登录：
    
    
    $ nerdctl login -u admin harbor.k8s.local
    Enter Password:
    ERRO[0004] failed to call tryLoginWithRegHost            error="failed to call rh.Client.Do: Get \"https://harbor.k8s.local/v2/\": x509: certificate signed by unknown authority" i=0
    FATA[0004] failed to call rh.Client.Do: Get "https://harbor.k8s.local/v2/": x509: certificate signed by unknown authority
    [root@master1 ~]#
    

可以看到还是会报证书相关的错误，只需要添加一个 `--insecure-registry` 参数即可解决该问题：
    
    
    $ nerdctl login -u admin --insecure-registry harbor.k8s.local
    Enter Password:
    WARN[0004] skipping verifying HTTPS certs for "harbor.k8s.local"
    WARNING: Your password will be stored unencrypted in /root/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store
    
    Login Succeeded
    

然后我们先随便拉一个镜像：
    
    
    $ nerdctl pull busybox:1.35.0
    docker.io/library/busybox:1.35.0:                                                 resolved       |++++++++++++++++++++++++++++++++++++++|
    index-sha256:8c40df61d40166f5791f44b3d90b77b4c7f59ed39a992fd9046886d3126ffa68:    done           |++++++++++++++++++++++++++++++++++++++|
    manifest-sha256:8cde9b8065696b65d7b7ffaefbab0262d47a5a9852bfd849799559d296d2e0cd: done           |++++++++++++++++++++++++++++++++++++++|
    config-sha256:d8c0f97fc6a6ac400e43342e67d06222b27cecdb076cbf8a87f3a2a25effe81c:   done           |++++++++++++++++++++++++++++++++++++++|
    layer-sha256:fc0cda0e09ab32c72c61d272bb409da4e2f73165c7bf584226880c9b85438e63:    done           |++++++++++++++++++++++++++++++++++++++|
    elapsed: 83.7s
    

然后将该镜像重新 tag 成 Harbor 上的镜像地址：
    
    
    $ nerdctl tag busybox:1.35.0 harbor.k8s.local/library/busybox:1.35.0
    

再执行 push 命令即可将镜像推送到 Harbor 上：
    
    
    $ nerdctl push --insecure-registry harbor.k8s.local/library/busybox:1.35.0
    INFO[0000] pushing as a reduced-platform image (application/vnd.docker.distribution.manifest.list.v2+json, sha256:29fe0126b13c3ea2641ca42c450fa69583d212dbd9b7b623814977b5b0945726)
    WARN[0000] skipping verifying HTTPS certs for "harbor.k8s.local"
    index-sha256:29fe0126b13c3ea2641ca42c450fa69583d212dbd9b7b623814977b5b0945726:    done           |++++++++++++++++++++++++++++++++++++++|
    manifest-sha256:8cde9b8065696b65d7b7ffaefbab0262d47a5a9852bfd849799559d296d2e0cd: done           |++++++++++++++++++++++++++++++++++++++|
    config-sha256:d8c0f97fc6a6ac400e43342e67d06222b27cecdb076cbf8a87f3a2a25effe81c:   done           |++++++++++++++++++++++++++++++++++++++|
    elapsed: 6.9 s                                                                    total:  2.2 Ki (333.0 B/s)
    

推送完成后，我们就可以在 Portal 页面上看到这个镜像的信息了：

![harbor project demo](https://picdn.youdianzhishi.com/images/1657189301886.png)

镜像 push 成功，同样可以测试下 pull：
    
    
    $ nerdctl rmi harbor.k8s.local/library/busybox:1.35.0
    Untagged: harbor.k8s.local/library/busybox:1.35.0@sha256:8c40df61d40166f5791f44b3d90b77b4c7f59ed39a992fd9046886d3126ffa68
    Deleted: sha256:cf4ac4fc01444f1324571ceb0d4f175604a8341119d9bb42bc4b2cb431a7f3a5
    $ nerdctl rmi busybox:1.35.0
    Untagged: docker.io/library/busybox:1.35.0@sha256:8c40df61d40166f5791f44b3d90b77b4c7f59ed39a992fd9046886d3126ffa68
    Deleted: sha256:cf4ac4fc01444f1324571ceb0d4f175604a8341119d9bb42bc4b2cb431a7f3a5
    $ nerdctl pull --insecure-registry  harbor.k8s.local/library/busybox:1.35.0
    WARN[0000] skipping verifying HTTPS certs for "harbor.k8s.local"
    harbor.k8s.local/library/busybox:1.35.0:                                          resolved       |++++++++++++++++++++++++++++++++++++++|
    index-sha256:29fe0126b13c3ea2641ca42c450fa69583d212dbd9b7b623814977b5b0945726:    done           |++++++++++++++++++++++++++++++++++++++|
    manifest-sha256:8cde9b8065696b65d7b7ffaefbab0262d47a5a9852bfd849799559d296d2e0cd: done           |++++++++++++++++++++++++++++++++++++++|
    config-sha256:d8c0f97fc6a6ac400e43342e67d06222b27cecdb076cbf8a87f3a2a25effe81c:   done           |++++++++++++++++++++++++++++++++++++++|
    layer-sha256:fc0cda0e09ab32c72c61d272bb409da4e2f73165c7bf584226880c9b85438e63:    done           |++++++++++++++++++++++++++++++++++++++|
    elapsed: 0.7 s                                                                    total:  2.2 Ki (3.2 KiB/s)
    
    $ nerdctl images
    REPOSITORY                          TAG       IMAGE ID        CREATED           PLATFORM       SIZE         BLOB SIZE
    harbor.k8s.local/library/busybox    1.35.0    29fe0126b13c    17 seconds ago    linux/amd64    1.2 MiB      757.7 KiB
    

但是上面我们也可以看到单独使用 containerd 比如通过 nerdctl 或者 ctr 命令访问 Harbor 镜像仓库的时候即使跳过证书校验或者配置上 CA 证书也是会出现证书错误的，这个时候我们需要去跳过证书校验或者指定证书路径才行。
    
    
    # 解决办法1.指定 -k 参数跳过证书校验。
    $ ctr images pull --user admin:Harbor12345 -k harbor.k8s.local/library/busybox:1.35.0
    
    # 解决办法2.指定CA证书、Harbor 相关证书文件路径。
    $ ctr images pull --user admin:Harbor12345 --tlscacert ca.crt harbor.k8s.local/library/busybox:1.35.0
    

但是如果直接使用 `ctrctl` 则是有效的：
    
    
    $ crictl pull harbor.k8s.local/library/busybox@sha256:29fe0126b13c3ea2641ca42c450fa69583d212dbd9b7b623814977b5b0945726
    Image is up to date for sha256:d8c0f97fc6a6ac400e43342e67d06222b27cecdb076cbf8a87f3a2a25effe81c
    

如果想要在 Kubernetes 中去使用那么就需要将 Harbor 的认证信息以 Secret 的形式添加到集群中去：
    
    
    $ kubectl create secret docker-registry harbor-auth --docker-server=https://harbor.k8s.local --docker-username=admin --docker-password=Harbor12345 --docker-email=info@ydzs.io -n default
    

然后我们使用上面的私有镜像仓库来创建一个 Pod：
    
    
    # test-harbor.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: harbor-registry-test
    spec:
      containers:
        - name: test
          image: harbor.k8s.local/library/busybox:1.35.0
          args:
            - sleep
            - "3600"
      imagePullSecrets:
        - name: harbor-auth
    

创建后可以查看该 Pod 是否能正常获取镜像：
    
    
    $ kubectl describe pod harbor-registry-test
    Name:         harbor-registry-test
    Namespace:    default
    Priority:     0
    Node:         node1/192.168.0.107
    Start Time:   Thu, 07 Jul 2022 18:52:39 +0800
    # ......
    Events:
      Type    Reason     Age   From               Message
      ----    ------     ----  ----               -------
      Normal  Scheduled  10s   default-scheduler  Successfully assigned default/harbor-registry-test to node1
      Normal  Pulling    10s   kubelet            Pulling image "harbor.k8s.local/library/busybox:1.35.0"
      Normal  Pulled     5s    kubelet            Successfully pulled image "harbor.k8s.local/library/busybox:1.35.0" in 4.670528883s
      Normal  Created    5s    kubelet            Created container test
      Normal  Started    5s    kubelet            Started container test
    

到这里证明上面我们的私有镜像仓库搭建成功了，大家可以尝试去创建一个私有的项目，然后创建一个新的用户，使用这个用户来进行 pull/push 镜像，Harbor 还具有其他的一些功能，比如镜像复制，Helm Chart 包托管等等，大家可以自行测试，感受下 Harbor 和官方自带的 registry 仓库的差别。
