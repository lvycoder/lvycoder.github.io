# 升级 Linkerd

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/linkerd/upgrade.md "编辑此页")

# 升级 Linkerd

Linkerd 最新的 2.12 版本已经发布了，这个庞大的版本为 Linkerd 引入了基于路由的策略，允许用户以完全零信任的方式定义和执行基于 HTTP 路由的授权策略。这些策略建立在 Linkerd 强大的工作负载身份之上，由双向 TLS 保护，并使用 Kubernetes 新推出的 Gateway API 的类型进行配置。

## 更新日志

Linkerd 2.12 是采用 `Gateway API` 作为核心配置机制的第一步。虽然这个 API 对于服务网格用例来说还不是完美的，但它为这个版本提供了一个强大的起点，更重要的是，在 Gateway API 的基础上构建将使我们能够将特定于 Linkerd 的配置对象的数量保持在最低限度，即使我们引入了新功能。这是我们为 Kubernetes 成为最简单和最轻量的服务网格的目标的重要组成部分。此外 2.12 版本还引入了访问日志记录，这是一个期待已久的功能，允许 Linkerd 生成 Apache 样式的请求日志。它增加了对 `iptables-nft` 的支持，并引入了许多其他改进和性能增强。

### Per-route 策略

Linkerd 的新的 per-route 策略扩展了现有的基于端口的策略，对服务如何被允许相互通信进行更精细的控制。这些策略是为采取零信任安全方法的组织设计的，这种方法不仅需要加密，还需要强大的工作负载身份和明确的授权。

  * 将网络视为对抗性的：它们不依赖 IP 地址，也不要求 CNI 层或底层网络的任何其他方面是安全的。
  * 使用安全的工作负载身份：Linkerd 的工作负载身份是由 ServiceAccounts 自动生成的，并在连接时通过双向 TLS 进行加密验证。
  * 在 Pod 级别上强制执行：每个连接和每个请求都经过验证。
  * 很容易的允许模式：有安全意识的采用者可以很容易地默认拒绝对敏感资源的访问，除非明确允许（"最小特权原则"）。



默认拒绝配置在 Kubernetes 中可能会有一些问题，因为 health 和 readiness 探针状态需要在没有授权的情况下通过。在 Linkerd 2.12 中，health 和 readiness 状态探测现在是默认授权的，但也可以明确授权，同时仍然锁定其他应用端点。

### Gateway API

Linkerd 2.12 提供了支持 Kubernetes Gateway API 的第一步。虽然 Gateway API 最初是作为 Kubernetes 中长期存在的 Ingress 资源的一个更丰富、更灵活的替代品而设计的，但它为描述服务网状流量提供了一个很好的基础，并允许 Linkerd 将其增加的配置保持在最低水平。

在 Linkerd 2.12 中，Linkerd 提供了 Gateway API 的部分实现来配置 Linkerd 的基于路由的策略。这样我们就可以开始使用 Gateway API，而不用实现规范中对 Linkerd 没有意义的部分。随着 Gateway API 的发展，也会慢慢地更好满足 Linkerd 的需求。

### 访问日志

Linkerd 2.12 还引入了访问日志记录，它允许代理发出 Apache 样式的请求日志。出于性能和资源利用率的原因，此功能默认关闭（尤其是对于高流量工作负载），但也可以在需要它的情况下轻松启用。

### 其他更新

Linkerd 2.12 还有大量的其他改进、性能提升和错误修复，包括：

  * 一个新的 `config.linkerd.io/shutdown-grace-period` 注解，用于配置代理的最大宽限期，以便优雅地关闭。
  * 一个新的 `iptables-nft` 模式，用于 Linkerd 的 init 容器中的 `iptables-nft` 支持。
  * 修复了某些控制平面组件在信任根轮换后未按要求重启的问题。
  * 修正了当在 Linkerd 命名空间中发现意外的 Pod 时，`linkerd check` 命令崩溃的问题。
  * 修改了 `proxy.await` 的 Helm 值，这样用户就可以在控制平面组件上禁用 `linkerd-await`。
  * 注释，允许 Linkerd 扩展部署在必要时被自动缩放器驱逐。
  * 能够在独立模式下运行 `Linkerd CNI` 插件。
  * 多集群扩展中的 ServiceAccount token Secret，支持 Kubernetes 版本>= v1.24。



## 升级

现在我们将集群中的 Linkerd 升级到最新的 2.12 版本。

首先需要更新 Linkerd CLI 工具，执行如下所示的命令即可：
    
    
    $ curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
    

这会将你的本地 CLI 升级到最新版本。当然我们有可以通过 [Linkerd 的 Release 页面](https://github.com/linkerd/linkerd2/releases/)直接下载对应平台的 CLI 安装包。
    
    
    $ wget https://github.91chi.fun/https://github.com//linkerd/linkerd2/releases/download/stable-2.12.0/linkerd2-cli-stable-2.12.0-darwin-arm64
    $ sudo mv linkerd2-cli-stable-2.12.0-darwin-arm64 /usr/local/bin/linkerd
    $ chmod +x /usr/local/bin/linkerd
    

验证 CLI 已安装并正确运行：
    
    
    $ linkerd version
    Client version: stable-2.12.0
    Server version: stable-2.11.1
    

可以看到 CLI 升级成功了，由于控制平面还没升级，所以看到的还是现在的 2.11.1 版本。

接下来就可以升级 Kubernetes 集群上的 Linkerd 控制平面了，不用担心，现有的数据平面将继续使用更新版本的控制平面运行，并且你的网格服务不会出现故障。

:::warning 注意

如果你使用的是 viz 插件自带的 Prometheus 组件，那么升级后数据会丢失，如果你配置的外置的 Prometheus 则不用担心该问题。

:::

### Linkerd SMI 扩展

如果你使用 CLI 安装了 Linkerd 2.11.x，并且正在使用 TrafficSplit CRD，则需要注意丢失 TS 的 CR，如果你不使用此 CRD，则可以忽略该注意事项。

TrafficSplit CRD 不再随 Linkerd 2.12.0 提供，而是由 `Linkerd SMI` 扩展提供。

同样首先从 Release 页面下载对应的可执行包：
    
    
    $ wget https://github.91chi.fun/https://github.com//linkerd/linkerd-smi/releases/download/v0.2.0/linkerd-smi-0.2.0-darwin-arm64
    $ chmod +x linkerd-smi-0.2.0-darwin-arm64
    $ sudo mv linkerd-smi-0.2.0-darwin-arm64 /usr/local/bin/linkerd-smi
    $ linkerd-smi version
    v0.2.0
    

同样 Linkerd SMI 也可以通过 CLI 工具进行安装，此扩展包含一个 `SMI-Adaptor`，它将 SMI 资源转换为本地 Linkerd 资源。
    
    
    $ linkerd smi install | kubectl apply -f -
    $ linkerd smi check
    

此外也可以通过下面的 Helm 方式来安装 Linkerd SMI 扩展。但在安装该扩展之前，你需要在 CRD 中添加以下注释和标签，以便 `linkerd-smi` chart 可以采用它：
    
    
    $ kubectl annotate --overwrite crd/trafficsplits.split.smi-spec.io \
      meta.helm.sh/release-name=linkerd-smi \
      meta.helm.sh/release-namespace=linkerd-smi
    # 添加smi repo仓库
    $ helm repo add l5d-smi https://linkerd.github.io/linkerd-smi
    $ helm upgrade --install linkerd-smi -n linkerd-smi --create-namespace l5d-smi/linkerd-smi
    Release "linkerd-smi" has been upgraded. Happy Helming!
    NAME: linkerd-smi
    LAST DEPLOYED: Sun Sep 11 14:54:02 2022
    NAMESPACE: linkerd-smi
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    The Linkerd SMI extension was successfully installed 🎉
    $ kubectl get pods -n linkerd-smi
    NAME                           READY   STATUS      RESTARTS        AGE
    namespace-metadata--1-jnttx    0/1     Completed   0               17m
    smi-adaptor-5788b875d4-r4b7w   2/2     Running     6 (5m53s ago)   17m
    

最后，你可以继续使用通常的 CLI 升级说明，但在应用 `linkerd upgrade --crds` 的输出时避免使用 `--prune` 标志以避免删除 TrafficSplit CRD！

### 升级

接下来我们可以直接使用 `linkerd upgrade` 命令来升级控制平面，该命令确保控制平面的所有现有配置和 mTLS 被保留下来。
    
    
    $ kubectl get crd |grep linkerd
    serverauthorizations.policy.linkerd.io                     2022-08-19T04:06:33Z
    servers.policy.linkerd.io                                  2022-08-19T04:06:33Z
    serviceprofiles.linkerd.io                                 2022-08-19T04:06:33Z
    $ linkerd upgrade --crds | \
      kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd \
      --prune-whitelist=apiextensions.k8s.io/v1/customresourcedefinition \
      --prune-whitelist=split.smi-spec.io/v1alpha2/trafficsplit \
      -f -
    customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.policy.linkerd.io created
    customresourcedefinition.apiextensions.k8s.io/httproutes.policy.linkerd.io created
    customresourcedefinition.apiextensions.k8s.io/meshtlsauthentications.policy.linkerd.io created
    customresourcedefinition.apiextensions.k8s.io/networkauthentications.policy.linkerd.io created
    customresourcedefinition.apiextensions.k8s.io/serverauthorizations.policy.linkerd.io configured
    customresourcedefinition.apiextensions.k8s.io/servers.policy.linkerd.io configured
    customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io configured
    customresourcedefinition.apiextensions.k8s.io/trafficsplits.split.smi-spec.io configured
    

注意，上面更新命令中我们使用了 `--prune` 标志，该标志可以删除在新版本中不再存在的前一版本的 Linkerd 资源，上面我们是更新新版本的 CRD 资源，可以看到新增了 4 个 CRD，因为现在引入了 Gateway API。
    
    
    $ kubectl get crd |grep linkerd
    authorizationpolicies.policy.linkerd.io                    2022-09-11T02:56:13Z
    httproutes.policy.linkerd.io                               2022-09-11T02:56:13Z
    meshtlsauthentications.policy.linkerd.io                   2022-09-11T02:56:14Z
    networkauthentications.policy.linkerd.io                   2022-09-11T02:56:14Z
    serverauthorizations.policy.linkerd.io                     2022-08-19T04:06:33Z
    servers.policy.linkerd.io                                  2022-08-19T04:06:33Z
    serviceprofiles.linkerd.io                                 2022-08-19T04:06:33Z
    

不过需要注意的是新增的 Gateway API 相关的 CRD 并不是原始 Kubernetes 下面定义的，而是也是在 `policy.linkerd.io` 的组下面，这是因为 Linkerd 对这些 CRD 也做了一些适配。

接下来直接使用下面的命令更新控制平面资源对象：
    
    
    $ linkerd upgrade | \
     kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd -f -
    

接下来，再次运行此命令并添加一些 `--prune-whitelist` 标志，这可以确保正确修剪某些集群范围的资源所必需的。
    
    
    $ linkerd upgrade | kubectl apply --prune -l linkerd.io/control-plane-ns=linkerd \
      --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrole \
      --prune-whitelist=rbac.authorization.k8s.io/v1/clusterrolebinding \
      --prune-whitelist=apiregistration.k8s.io/v1/apiservice -f -
    

升级过程完成后，同样可以运行检查命令来确保一切正常：
    
    
    $ linkerd check
    

该命令将针对控制平面进行一系列检查，并确保其正常运行。

现在再次查看 Linkerd 版本，正常 Server 端的版本也更新了。
    
    
    $ linkerd version
    Client version: stable-2.12.0
    Server version: stable-2.12.0
    

接着我们就可以升级数据平面了，最简单的方法是在你的服务上运行滚动部署，允许代理注入器在它们出现时注入最新版本的代理。
    
    
    $ kubectl -n <namespace> rollout restart deploy
    

一般来说稳定版的控制平面与上一个稳定版的数据平面是兼容的，所以数据平面的升级可以在控制平面升级后的任何时候进行，但是不建议超过一个稳定版本的差距。

同样更新完成后可以使用 check 命令来校验数据平面状态。
    
    
    $ linkerd check --proxy
    # ......
    linkerd-data-plane
    ------------------
    √ data plane namespace exists
    √ data plane proxies are ready
    ‼ data plane is up-to-date
        some proxies are not running the current version:
            * emoji-696d9d8f95-5vn9w (stable-2.11.1)
            * vote-bot-646b9fd6fd-8xj2j (stable-2.11.1)
            * voting-ff4c54b8d-xhjv7 (stable-2.11.1)
            * web-5f86686c4d-58p7k (stable-2.11.1)
            * web-svc-2-f9d77474f-vxlrh (stable-2.11.1)
            * ingress-nginx-controller-f56c7f6fd-rxhrs (stable-2.11.1)
        see https://linkerd.io/2.12/checks/#l5d-data-plane-version for hints
    ‼ data plane and cli versions match
        emoji-696d9d8f95-5vn9w running stable-2.11.1 but cli running stable-2.12.0
        see https://linkerd.io/2.12/checks/#l5d-data-plane-cli-version for hints
    √ data plane pod labels are configured correctly
    √ data plane service labels are configured correctly
    √ data plane service annotations are configured correctly
    √ opaque ports are properly annotated
    
    Linkerd extensions checks
    =========================
    
    - Running smi extension check
    

该命令通过一组检查来验证数据平面是否正常运行，并将列出仍在运行旧版本代理的 pod，然后我们可以根据实际情况去升级对应的 pod 即可。

### Linkerd Viz 扩展

另外还有一个需要注意的是 viz 插件，在最新版本中已经没有内置 grafana 了，所以这里我们先直接将该插件卸载干净（该插件不会影响网格的核心功能），然后重新安装最新版本。
    
    
    $ linkerd viz install | kubectl delete -f -
    

卸载完成后重新安装，由于新版本已经没有内置 Grafana 了，我们重新安装的使用可以通过 `--set grafana.url` 来指定外部的 Grafana 地址（如果是集群外的地址可以通过 `grafana.externalUrl` 参数指定），同样我们还可以使用外部的 Prometheus：
    
    
    $ linkerd viz install --set grafana.url=grafana:3000,prometheusUrl=http://prometheus.kube-mon.svc.cluster.local:9090,prometheus.enabled=false | kubectl apply -f -
    

重新安装后查看 viz 的 pod 列表：
    
    
    $ kubectl get pods -n linkerd-viz
    NAME                           READY   STATUS    RESTARTS   AGE
    metrics-api-674bf48d7f-kzr5b   2/2     Running   0          17m
    tap-67d6d8ff4d-q7nqn           2/2     Running   0          5m21s
    tap-injector-7c565f754-jgvc5   2/2     Running   0          5m20s
    web-87b958bcf-d5pfp            2/2     Running   0          5m20s
    

可以看到现在没有了 Grafana 和 Prometheus 了，因为我们对接的外部 Prometheus，而 Grafana 则是新版本中没有内置使用了，上面我们指定的 Grafana 地址在 viz 同命名空间之下，所以这里我们手动安装一个即可。

:::tip Grafana 实例

如果单个 Grafana 实例指向多个 Linkerd，你可以通过其 UID 中的不同前缀分隔仪表板，可以在每个 Linkerd 实例的 `grafana.uidPrefix` 设置中配置这些前缀。

:::

这里我们直接使用 Helm Chart 来进行安装，定制一个如下所示的 values 文件：
    
    
    podAnnotations:
      linkerd.io/inject: enabled
    
    grafana.ini:
      server:
        root_url: "%(protocol)s://%(domain)s:/grafana/"
      auth:
        disable_login_form: true
      auth.anonymous:
        enabled: true
        org_role: Editor
      auth.basic:
        enabled: false
      analytics:
        check_for_updates: false
      panels:
        disable_sanitize_html: true
      log:
        mode: console
      log.console:
        format: text
        level: info
    
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: prometheus
            type: prometheus
            access: proxy
            orgId: 1
            url: http://prometheus.kube-mon.svc.cluster.local:9090
            isDefault: true
            jsonData:
              timeInterval: "5s"
            editable: true
    
    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
          - name: "default"
            orgId: 1
            folder: ""
            type: file
            disableDeletion: false
            editable: true
            options:
              path: /var/lib/grafana/dashboards/default
    
    dashboards:
      default:
        # all these charts are hosted at https://grafana.com/grafana/dashboards/{id}
        top-line:
          gnetId: 15474
          revision: 3
          datasource: prometheus
        health:
          gnetId: 15486
          revision: 2
          datasource: prometheus
        kubernetes:
          gnetId: 15479
          revision: 2
          datasource: prometheus
        namespace:
          gnetId: 15478
          revision: 2
          datasource: prometheus
        deployment:
          gnetId: 15475
          revision: 5
          datasource: prometheus
        pod:
          gnetId: 15477
          revision: 2
          datasource: prometheus
        service:
          gnetId: 15480
          revision: 2
          datasource: prometheus
        route:
          gnetId: 15481
          revision: 2
          datasource: prometheus
        authority:
          gnetId: 15482
          revision: 2
          datasource: prometheus
        cronjob:
          gnetId: 15483
          revision: 2
          datasource: prometheus
        job:
          gnetId: 15487
          revision: 2
          datasource: prometheus
        daemonset:
          gnetId: 15484
          revision: 2
          datasource: prometheus
        replicaset:
          gnetId: 15491
          revision: 2
          datasource: prometheus
        statefulset:
          gnetId: 15493
          revision: 2
          datasource: prometheus
        replicationcontroller:
          gnetId: 15492
          revision: 2
          datasource: prometheus
        prometheus:
          gnetId: 15489
          revision: 2
          datasource: prometheus
        prometheus-benchmark:
          gnetId: 15490
          revision: 2
          datasource: prometheus
        multicluster:
          gnetId: 15488
          revision: 2
          datasource: prometheus
    

上面的 values 文件中我们注入了 `linkerd.io/inject: enabled` 这个注解，为其注入 Linkerd 的 proxy，然后还要注意配置 Prometheus 数据源地址。
    
    
    $ helm repo add grafana https://grafana.github.io/helm-charts
    $ helm upgrade --install grafana -n linkerd-viz grafana/grafana -f values.yaml
    

如果我们已经有一个外部的 Grafana，那么在安装的时候可以直接通过 `grafana.externalUrl` 来指定：
    
    
    $ linkerd viz install --set grafana.externalUrl=http://192.168.0.106:30403,prometheusUrl=http://prometheus.kube-mon.svc.cluster.local:9090,prometheus.enabled=false | kubectl apply -f -
    

这样更新后记得要在外部 Grafana 中导入 Linkerd 相关的 Dashboard，可以从 Grafana 官网 <https://grafana.com/orgs/linkerd> 获取。

比如我们导入 Deployments 的 dashboard，可以导入 `15475` 这个 ID，或者下载 JSON 文件上传导入。

![Linkerd Deployments](https://picdn.youdianzhishi.com/images/1662888997022.png)

导入后重新访问 Viz 的 Dashboard：

![linkerd viz](https://picdn.youdianzhishi.com/images/1662893791522.png)

同样点击页面上的 Grafana 图标就可以直接跳转到 Grafana Dashboard 页面：

![Grafana](https://picdn.youdianzhishi.com/images/1662893872287.png)

到这里我们就完成了 Linkerd 的升级。
