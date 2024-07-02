Helm 使用一种名为 charts 的包格式，一个 chart 是描述一组相关的 Kubernetes 资源的文件集合，单个 chart 可能用于部署简单的应用，比如 memcached pod，或者复杂的应用，比如一个带有 HTTP 服务、数据库、缓存等等功能的完整 web 应用程序。

Charts 是创建在特定目录下面的文件集合，然后可以将它们打包到一个版本化的存档中来部署。接下来我们就来看看使用 Helm 构建 charts 的一些基本方法。


## 文件结构

chart 被组织为一个目录中的文件集合，目录名称就是 chart 的名称（不包含版本信息），下面是一个 WordPress 的 chart，会被存储在 wordpress/ 目录下面，基本结构如下所示：

```shell
wordpress/
  Chart.yaml          # 包含当前 chart 信息的 YAML 文件
  LICENSE             # 可选：包含 chart 的 license 的文本文件
  README.md           # 可选：一个可读性高的 README 文件
  values.yaml         # 当前 chart 的默认配置 values
  values.schema.json  # 可选: 一个作用在 values.yaml 文件上的 JSON 模式
  charts/             # 包含该 chart 依赖的所有 chart 的目录
  crds/               # Custom Resource Definitions
  templates/          # 模板目录，与 values 结合使用时，将渲染生成 Kubernetes 资源清单文件
  templates/NOTES.txt # 可选: 包含简短使用使用的文本文件
```

另外 Helm 会保留 charts/、crds/ 以及 templates/ 目录以及上面列出的文件名的使用。