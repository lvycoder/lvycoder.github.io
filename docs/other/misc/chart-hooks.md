# Chart Hooks

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/helm/templates/hooks.md "编辑此页")

# Chart Hooks

Helm 也提供了一种 Hook 机制，可以允许 chart 开发人员在 release 生命周期的某些时间点进行干预。比如，可以使用 hook 来进行下面的操作：

  * 在加载任何 charts 之前，在安装的时候加载 ConfigMap 或者 Secret
  * 在安装新的 chart 之前，执行一个 Job 来备份数据库，然后在升级后执行第二个 Job 还原数据
  * 在删除 release 之前运行一个 JOb，以在删除 release 之前适当地取消相关服务



Hooks 的工作方式类似于普通的模板，但是他们具有特殊的注解，这些注解使 Helm 可以用不同的方式来使用他们。

## Hooks

在 Helm 中定义了如下一些可供我们使用的 Hooks：

  * 预安装`pre-install`：在模板渲染后，kubernetes 创建任何资源之前执行
  * 安装后`post-install`：在所有 kubernetes 资源安装到集群后执行
  * 预删除`pre-delete`：在从 kubernetes 删除任何资源之前执行删除请求
  * 删除后`post-delete`：删除所有 release 的资源后执行
  * 升级前`pre-upgrade`：在模板渲染后，但在任何资源升级之前执行
  * 升级后`post-upgrade`：在所有资源升级后执行
  * 预回滚`pre-rollback`：在模板渲染后，在任何资源回滚之前执行
  * 回滚后`post-rollback`：在修改所有资源后执行回滚请求
  * 测试`test`：在调用 Helm `test` 子命令的时候执行（可以查看[测试文档](https://helm.sh/docs/chart_tests/)）



## 生命周期

Hooks 允许开发人员在 release 的生命周期中的一些关键节点执行一些钩子函数，我们正常安装一个 chart 包的时候的生命周期如下所示：

  *     1. 用户运行 `helm install foo`
  *     1. Helm 库文件调用安装 API
  *     1. 经过一些验证，Helm 库渲染 `foo` 模板
  *     1. Helm 库将产生的资源加载到 kubernetes 中去
  *     1. Helm 库将 release 对象和其他数据返回给客户端
  *     1. Helm 客户端退出



如果开发人员在 `install` 的生命周期中定义了两个 hook：`pre-install`和`post-install`，那么我们安装一个 chart 包的生命周期就会多一些步骤了：

  *     1. 用户运行`helm install foo`
  *     1. Helm 库文件调用安装 API
  *     1. 在 `crds/` 目录下面的 CRDs 被安装
  *     1. 经过一些验证，Helm 库渲染 `foo` 模板
  *     1. Helm 库将 hook 资源加载到 kubernetes 中，准备执行`pre-install` hooks
  *     1. Helm 库会根据权重对 hooks 进行排序（默认分配权重0，权重相同的 hook 按升序排序）
  *     1. Helm 库然后加载最低权重的 hook
  *     1. Helm 库会等待，直到 hook 准备就绪
  *     1. Helm 库将产生的资源加载到 kubernetes 中，注意如果添加了 `--wait` 参数，Helm 库会等待所有资源都准备好，在这之前不会运行 `post-install` hook
  *     1. Helm 库执行 `post-install` hook（加载 hook 资源）
  *     1. Helm 库等待，直到 hook 准备就绪
  *     1. Helm 库将 release 对象和其他数据返回给客户端
  *     1. Helm 客户端退出



等待 hook 准备就绪，这是一个阻塞的操作，如果 hook 中声明的是一个 Job 资源，Helm 将等待 Job 成功完成，如果失败，则发布失败，在这个期间，Helm 客户端是处于暂停状态的。

对于所有其他类型，只要 kubernetes 将资源标记为加载（添加或更新），资源就被视为就绪状态，当一个 hook 声明了很多资源是，这些资源是被串行执行的。

另外需要注意的是 hook 创建的资源不会作为 release 的一部分进行跟踪和管理，一旦 Helm 验证了 hook 已经达到了就绪状态，它就不会去管它了。

所以，如果我们在 hook 中创建了资源，那么不能依赖 `helm uninstall` 去删除资源，因为 hook 创建的资源已经不受控制了，要销毁这些资源，你需要将 `helm.sh/hook-delete-policy` 这个 annotation 添加到 hook 模板文件中，或者设置 [Job 资源的生存（TTL）字段](https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/)。

## 编写 Hook

Hooks 就是 Kubernetes 资源清单文件，在元数据部分带有一些特殊的注解，因为他们是模板文件，所以你可以使用普通模板所有的功能，包括读取 `.Values`、`.Release` 和 `.Template`。

例如，在 `templates/post-install-job.yaml` 文件中声明一个 post-install 的 hook：
    
    
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: "{{ .Release.Name }}"
      labels:
        app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
        app.kubernetes.io/instance: {{ .Release.Name | quote }}
        app.kubernetes.io/version: {{ .Chart.AppVersion }}
        helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
      annotations:
        # 因为添加了这个 hook，所以我们这个资源被定义为了 hook
        # 如果没有这行，则当前这个 Job 会被当成 release 的一部分内容。
        "helm.sh/hook": post-install
        "helm.sh/hook-weight": "-5"
        "helm.sh/hook-delete-policy": hook-succeeded
    spec:
      template:
        metadata:
          name: "{{ .Release.Name }}"
          labels:
            app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
            app.kubernetes.io/instance: {{ .Release.Name | quote }}
            helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
        spec:
          restartPolicy: Never
          containers:
          - name: post-install-job
            image: "alpine:3.3"
            command: ["/bin/sleep","{{ default "10" .Values.sleepyTime }}"]
    

当前这个模板成为 hook 的原因就是添加这个注解：
    
    
    annotations:
      "helm.sh/hook": post-install
    

一种资源也可以实现多个 hooks：
    
    
    annotations:
      "helm.sh/hook": post-install,post-upgrade
    

类似的，实现给定 hook 的资源数量也没有限制，比如可以将 secret 和一个 configmap 都声明为 `pre-install` hook。

当子 chart 声明 hooks 的时候，也会对其进行调用，顶层的 chart 无法禁用子 chart 所声明的 hooks。可以为 hooks 定义权重，这将有助于确定 hooks 的执行顺序：
    
    
    annotations:
      "helm.sh/hook-weight": "5"
    

hook 权重可以是正数也可以是负数，但是必须用字符串表示，当 Helm 开始执行特定种类的 hooks 的时候，它将以升序的方式对这些 hooks 进行排序。

## Hook 删除策略

我们还可以定义确定何时删除相应 hook 资源的策略，hook 删除策略可以使用下面的注解进行定义：
    
    
    annotations:
      "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    

我们也可以选择一个或多个已定义的注解：

  * `before-hook-creation`：运行一个新的 hook 之前删除前面的资源（默认）
  * `hook-succeeded`：hook 成功执行后删除资源
  * `hook-failed`：hook 如果执行失败则删除资源



如果未指定任何 hook 删除策略注解，则默认情况下会使用 `before-hook-creation` 策略。
