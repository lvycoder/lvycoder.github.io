# Values 文件

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/helm/templates/values.md "编辑此页")

# Values 文件

前面我们介绍了 Helm 模板提供的内置对象，其中就有一个内置对象 `Values`，该对象提供对传递到 chart 中的 values 值的访问，其内容主要有4个来源：

  * chart 文件中的 `values.yaml` 文件
  * 如果这是子 chart，父 chart 的 `values.yaml` 文件
  * 用 `-f` 参数传递给 `helm install` 或 `helm upgrade` 的 values 值文件（例如 `helm install -f myvals.yaml ./mychart`）
  * 用 `--set` 传递的各个参数（例如 `helm install --set foo=bar ./mychart`）



`values.yaml` 文件是默认值，可以被父 chart 的 `values.yaml` 文件覆盖，而后者又可以由用户提供的 values 值文件覆盖，而该文件又可以被 `--set` 参数覆盖。

values 值文件是纯 YAML 文件，我们可以来编辑 `mychart/values.yaml` 文件然后编辑 `ConfigMap` 模板。删除 `values.yaml` 中的默认设置后，我们将只设置一个参数：
    
    
    favoriteDrink: coffee
    

现在我们可以在模板中直接使用它：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-configmap
    data:
      myvalue: "Hello World"
      drink: {{ .Values.favoriteDrink }}
    

可以看到在最后一行我们将 `favoriteDrink` 作为 `Values` 的属性进行访问：`{{ .Values.favoriteDrink }}`。我们可以来看看是如何渲染的：
    
    
    ➜ helm install --generate-name --dry-run --debug ./mychart
    install.go:148: [debug] Original chart version: ""
    install.go:165: [debug] CHART PATH: /Users/ych/devs/workspace/yidianzhishi/course/k8strain/content/helm/manifests/mychart
    
    NAME: mychart-1575963545
    LAST DEPLOYED: Tue Dec 10 15:39:06 2019
    NAMESPACE: default
    STATUS: pending-install
    REVISION: 1
    TEST SUITE: None
    USER-SUPPLIED VALUES:
    {}
    
    COMPUTED VALUES:
    favoriteDrink: coffee
    
    HOOKS:
    MANIFEST:
    ---
    # Source: mychart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mychart-1575963545-configmap
    data:
      myvalue: "Hello World"
      drink: coffee
    

由于在默认的 `values.yaml` 文件中将 favoriteDrink 设置为了 coffee，所以这就是模板中显示的值，我们可以通过在调用 `helm install` 的过程中添加 `--set` 参数来覆盖它：
    
    
    ➜ helm install --generate-name --dry-run --debug --set favoriteDrink=slurm ./mychart
    install.go:148: [debug] Original chart version: ""
    install.go:165: [debug] CHART PATH: /Users/ych/devs/workspace/yidianzhishi/course/k8strain/content/helm/manifests/mychart
    
    NAME: mychart-1575963760
    LAST DEPLOYED: Tue Dec 10 15:42:43 2019
    NAMESPACE: default
    STATUS: pending-install
    REVISION: 1
    TEST SUITE: None
    USER-SUPPLIED VALUES:
    favoriteDrink: slurm
    
    COMPUTED VALUES:
    favoriteDrink: slurm
    
    HOOKS:
    MANIFEST:
    ---
    # Source: mychart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mychart-1575963760-configmap
    data:
      myvalue: "Hello World"
      drink: slurm
    

因为 `--set` 的优先级高于默认的 `values.yaml` 文件，所以我们的模板会生成 `drink: slurm`。Values 值文件也可以包含更多结构化的内容，例如我们可以在 `values.yaml` 文件中创建一个 favorite 的部分，然后在其中添加几个 keys：
    
    
    favorite:
      drink: coffee
      food: pizza
    

现在我们再去修改下我们的模板：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-configmap
    data:
      myvalue: "Hello World"
      drink: {{ .Values.favorite.drink }}
      food: {{ .Values.favorite.food }}
    

虽然我们可以通过这种方式来构造数据，但是还是建议你将 values 树保持更浅，这样在使用的时候更加简单。当我们考虑为子 chart 分配 values 值的时候，我们就可以看到如何使用树形结构来命名 values 值了。

## 删除默认 KEY

如果你需要从默认值中删除 key，则可以将该 key 的值覆盖为 null，在这种情况下，Helm 将从覆盖的 values 中删除该 key。例如，在 Drupal chart 中配置一个 liveness 探针:
    
    
    livenessProbe:
      httpGet:
        path: /user/login
        port: http
      initialDelaySeconds: 120
    

如果你想使用 `--set livenessProbe.exec.command=[cat, docroot/CHANGELOG.txt]` 将 livenessProbe 的处理程序覆盖为 `exec` 而不是 `httpGet`，则 Helm 会将默认键和覆盖键合并在一起，如下所示：
    
    
    livenessProbe:
      httpGet:
        path: /user/login
        port: http
      exec:
        command:
        - cat
        - docroot/CHANGELOG.txt
      initialDelaySeconds: 120
    

但是，这样却有一个问题，因为你不能声明多个 livenessProbe 处理程序，为了解决这个问题，你可以让 Helm 通过将 `livenessProbe.httpGet` 设置为 null 来删除它：
    
    
    ➜ helm install stable/drupal --set image=my-registry/drupal:0.1.0 --set livenessProbe.exec.command=[cat, docroot/CHANGELOG.txt] --set livenessProbe.httpGet=null
    

到这里我们已经了解到了几个内置对象，并利用它们将信息注入到了模板中，现在我们来看看模板引擎的另外方面：函数和管道。
