## Helmfile

前面我们已经了解了 Helm 的使用，但在实际使用场景中的一些需求 Helm 并不能很好的满足，需要进行一些修改和适配，比如当我们需要同时部署多个 chart、不同部署环境的区分以及 chart 的版本控制的时候，这个时候我们可以使用一个 Helmfile 的工具来解决这些场景的问题。

Helmfile 是一个声明式 Helm Chart 管理工具，通过一个 helmfile.yaml 文件来帮助用户管理和维护众多的 Helm Chat，其最主要作用是：

● 集成在 CI/CD 系统中，提高部署的可观测性和可重复性，区分环境，免去各种 --set 造成的困扰。
● 方便对 helm chart 进行版本控制，如指定版本范围、锁定版本等。
● 定期同步，避免环境中出现不符合预期的配置。

Helmfile 的主要特点有：

● 声明式：编写、版本控制、应用所需的状态文件以实现可见性和可再现性。
● 模块：将基础架构的通用模式模块化，通过 Git、S3 等进行分发，以便在整个公司复用。
● 多功能性：管理由 charts、kustomizations 和 Kubernetes 资源目录组成的集群，将所有内容转换为 Helm releases。
● Patch：JSON/Strategic-Merge 在 helm 安装之前 patch Kubernetes 资源，无需分叉上游 charts。


## 安装

helmfile 提供了多种安装方式，我们可以直接在 release 页面 https://github.com/helmfile/helmfile/ 选择合适的包下载，比如我们这里是 Mac m1 环境就选择 darwin_arm64 的包：

```
$ wget https://github.com/helmfile/helmfile/releases/download/v0.151.0/helmfile_0.151.0_darwin_arm64.tar.gz
$ tar -xvf helmfile_0.151.0_darwin_arm64.tar.gz
x LICENSE
x README-zh_CN.md
x README.md
x helmfile
$ chmod +x helmfile && sudo mv helmfile /usr/local/bin
$ helmfile -v
helmfile version 0.151.0
```

安装一些插件

```
$ helmfile -v                                                                                                         (bj-k8s/default)
(base)
# beiyiwangdejiyi @ beiyiwangdejiyideMacBook-Pro in ~/Desktop/tools/Helm-tools on git:main x [10:55:35] C:130
$ helmfile init                                                                                                       (bj-k8s/default)
helm version is too low, the current version is 3.12.2+g1e210a2, the required version is 3.14.4
use: 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3' [y/n]: y
Downloading https://get.helm.sh/helm-v3.15.2-darwin-arm64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
The helm plugin "diff" version is too low, do you want to update it? [y/n]: y
Update helm plugin diff
Downloading https://github.com/databus23/helm-diff/releases/latest/download/helm-diff-macos-arm64.tgz
Preparing to install into /Users/beiyiwangdejiyi/Library/helm/plugins/helm-diff
Updated plugin: diff

The helm plugin "secrets" is not installed, do you want to install it? [y/n]: y
Install helm plugin secrets
Installed plugin: secrets

The helm plugin "s3" is not installed, do you want to install it? [y/n]: y
Install helm plugin s3
Downloading and installing helm-s3 v0.16.0 ...
Checksum is valid.
Installed plugin: s3

The helm plugin "helm-git" is not installed, do you want to install it? [y/n]: y
Install helm plugin helm-git
Installed plugin: helm-git

helmfile initialization completed!
```

如果没有执行 init 命令则需要手动安装 helm-diff 插件，该插件是必须的，其他插件可以根据需要选择安装

```
$ helm plugin install https://github.com/databus23/helm-diff
```

## 使用

接下来我们来了解下 Helmfile 的具体使用，首先我们从一个简单的示例开始，假设 helmfile.yaml 表示你的 Helm release 的期望状态如下所示：

```
# helmfile.yaml
repositories:
  - name: prometheus-community
    url: https://prometheus-community.github.io/helm-charts

releases:
  - name: prom-norbac-ubuntu
    namespace: prometheus
    chart: prometheus-community/prometheus
    set:
      - name: rbac.create
        value: false
```
