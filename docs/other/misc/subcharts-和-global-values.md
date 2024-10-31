# Subcharts 和 Global Values

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/helm/templates/subcharts_and_globals.md "编辑此页")

# Subcharts 和 Global Values

到现在为止，我们从单一模板，到多个模板文件，但是都仅仅是处理的一个 chart 包，但是 charts 可能具有一些依赖项，我们称为 `subcharts（子 chart）`，接下来我们将创建一个子 chart。

同样在深入了解之前，我们需要了解下子 chart 相关的一些信息。

  * 子 chart 是**独立** 的，这意味着子 chart 不能显示依赖其父 chart
  * 所以子 chart 无法访问其父级的值
  * 父 chart 可以覆盖子 chart 的值
  * Helm 中有可以被所有 charts 访问的全局值的概念



## 创建子chart

同样还是在之前操作的 `mychart/` 这个 chart 包中，我们来尝试添加一些新的子 chart：
    
    
    ➜ cd mychart/charts
    ➜ helm create mysubchart
    Creating mysubchart
    ➜ rm -rf mysubchart/templates/*.*
    

和前面一样，我们删除了所有的基本模板，这样我们可以从头开始。

## 添加 values 和 模板

接下来我们为 mysubchart 这个子 chart 创建一个简单的模板和 values 值文件，`mychart/charts/mysubchart` 中已经有一个 `values.yaml` 文件了，在文件中添加下面的 values：
    
    
    dessert: cake
    

下面我们再创建一个新的 ConfigMap 模板 `mychart/charts/mysubchart/templates/configmap.yaml`：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-cfgmap2
    data:
      dessert: {{ .Values.dessert }}
    

因为每个子 chart 都是独立的 chart，所以我们可以单独测试 `mysubchart`：
    
    
    ➜ helm install --generate-name --dry-run --debug mychart/charts/mysubchart
    install.go:148: [debug] Original chart version: ""
    install.go:165: [debug] CHART PATH: /Users/ych/devs/workspace/yidianzhishi/course/k8strain/content/helm/manifests/mychart/charts/mysubchart
    
    NAME: mysubchart-1576050755
    LAST DEPLOYED: Wed Dec 11 15:52:36 2019
    NAMESPACE: default
    STATUS: pending-install
    REVISION: 1
    TEST SUITE: None
    USER-SUPPLIED VALUES:
    {}
    
    COMPUTED VALUES:
    dessert: cake
    
    HOOKS:
    MANIFEST:
    ---
    # Source: mysubchart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mysubchart-1576050755-cfgmap2
    data:
      dessert: cake
    

## 从父 chart 覆盖 values

我们原来的 chart - mychart 现在是 mysubchart 的父级 chart 了。由于 mychart 是父级，所以我们可以在 mychart 中指定配置，并将该配置发送到 mysubchart 中去，比如，我们可以这样修改 `mychart/values.yaml`：
    
    
    favorite:
      drink: coffee
      food: pizza
    pizzaToppings:
      - mushrooms
      - cheese
      - peppers
      - onions
    
    mysubchart:
      dessert: ice cream
    

最后两行，`mysubchart` 部分中的所有指令都回被发送到 `mysubchart` 子 chart 中，所以，如果我们现在渲染模板，我们可以看到 `mysubchart` 的 ConfigMap 会被渲染成如下的内容：
    
    
    # Source: mychart/charts/mysubchart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mychart-1576051914-cfgmap2
    data:
      dessert: ice cream
    

我们可以看到顶层的 values 值覆盖了子 chart 中的值。这里有一个细节需要注意，我们没有将 `mychart/charts/mysubchart/templates/configmap.yaml` 模板更改为指向 `.Values.mysubchart.dessert`，因为从该模板的绝度来看，该值仍然位于 `.Values.dessert`，当模板引擎传递 values 值的时候，它会设置这个作用域，所以，对于 `mysubchart` 模板，`.Values` 中仅仅提供用于该子 chart 的值。

但是有时候如果我们确实希望某些值可以用于所有模板，这个时候就可以使用全局 chart values 值来完成了。

## 全局值

全局值是可以从任何 chart 或子 chart 中都可以访问的值，全局值需要显示的声明，不能将现有的非全局对象当作全局对象使用。

Values 数据类型具有一个名为 `Values.global` 的保留部分，可以在其中设置全局值，我们在 `mychart/values.yaml` 文件中添加一个全局值：
    
    
    favorite:
      drink: coffee
      food: pizza
    pizzaToppings:
      - mushrooms
      - cheese
      - peppers
      - onions
    
    mysubchart:
      dessert: ice cream
    
    global:
      salad: caesar
    

由于全局值的原因，在 `mychart/templates/configmap.yaml` 和 `mysubchart/templates/configmap.yaml` 下面都应该可以以 `{{ .Values.global.salad }}` 的形式来访问这个值。

`mychart/templates/configmap.yaml`：
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-configmap
    data:
      salad: {{ .Values.global.salad }}
    

`mysubchart/templates/configmap.yaml`:
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-cfgmap2
    data:
      dessert: {{ .Values.dessert }}
      salad: {{ .Values.global.salad }}
    

然后我们渲染这个模板，可以得到如下所示的内容：
    
    
    ---
    # Source: mychart/charts/mysubchart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mychart-1576053485-cfgmap2
    data:
      dessert: ice cream
      salad: caesar
    ---
    # Source: mychart/templates/configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: mychart-1576053485-configmap
    data:
      salad: caesar
    

全局值对于传递这样的数据比较有用。

## 共享模板

父级 chart 和子 chart 可以共享模板，任何 chart 中已定义的块都可以用于其他 chart。比如，我们可以定义一个简单的模板，如下所示：
    
    
    {{- define "labels" }}from: mychart{{ end }}
    

前面我们提到过可以使用在模板中使用 `include` 和 `template`，但是使用 `include` 的一个优点是可以动态引入模板的内容：
    
    
    {{ include $mytemplate }}
    
