# PromQL

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/monitor/promql.md "编辑此页")

# PromQL

Prometheus 通过指标名称（metrics name）以及对应的一组标签（label）唯一定义一条时间序列。指标名称反映了监控样本的基本标识，而 label 则在这个基本特征上为采集到的数据提供了多种特征维度。用户可以基于这些特征维度过滤、聚合、统计从而产生新的计算后的一条时间序列。

`PromQL` 是 Prometheus 内置的数据查询语言，其提供对时间序列数据丰富的查询，聚合以及逻辑运算能力的支持。并且被广泛应用在 Prometheus 的日常应用当中，包括对数据查询、可视化、告警处理。可以这么说，`PromQL` 是 Prometheus 所有应用场景的基础，理解和掌握 `PromQL` 是我们使用 Prometheus 必备的技能。

## 时间序列

前面我们通过 node-exporter 暴露的 metrics 服务，Prometheus 可以采集到当前主机所有监控指标的样本数据。例如：
    
    
    # HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
    # TYPE node_cpu_seconds_total counter
    node_cpu_seconds_total{cpu="0",mode="idle"} 6.62885731e+06
    # HELP node_load1 1m load average.
    # TYPE node_load1 gauge
    node_load1 2.29
    

其中非 `#` 开头的每一行表示当前 node-exporter 采集到的一个监控样本：`node_cpu_seconds_total` 和 `node_load1` 表明了当前指标的名称、大括号中的标签则反映了当前样本的一些特征和维度、浮点数则是该监控样本的具体值。

Prometheus 会将所有采集到的样本数据以时间序列的方式保存在**内存数据库** 中，并且定时保存到硬盘上。时间序列是按照时间戳和值的序列顺序存放的，我们称之为向量(vector)，每条时间序列通过指标名称(metrics name)和一组标签集(labelset)命名。如下所示，可以将时间序列理解为一个以时间为 X 轴的数字矩阵：
    
    
      ^
      │   . . . . . . . . . . . . . . . . .   . .   node_cpu_seconds_total{cpu="cpu0",mode="idle"}
      │     . . . . . . . . . . . . . . . . . . .   node_cpu_seconds_total{cpu="cpu0",mode="system"}
      │     . . . . . . . . . .   . . . . . . . .   node_load1{}
      │     . . . . . . . . . . . . . . . .   . .
      v
        <------------------ 时间 ---------------->
    

在时间序列中的每一个点称为一个样本（sample），样本由以下三部分组成：

  * 指标(metric)：metric name 和描述当前样本特征的 labelsets
  * 时间戳(timestamp)：一个精确到毫秒的时间戳
  * 样本值(value)： 一个 float64 的浮点型数据表示当前样本的值



如下所示：
    
    
    <--------------- metric ---------------------><-timestamp -><-value->
    http_request_total{status="200", method="GET"}@1434417560938 => 94355
    http_request_total{status="200", method="GET"}@1434417561287 => 94334
    
    http_request_total{status="404", method="GET"}@1434417560938 => 38473
    http_request_total{status="404", method="GET"}@1434417561287 => 38544
    
    http_request_total{status="200", method="POST"}@1434417560938 => 4748
    http_request_total{status="200", method="POST"}@1434417561287 => 4785
    

在形式上，所有的指标(Metric)都通过如下格式表示：
    
    
    <metric name>{<label name> = <label value>, ...}
    

  * 指标的名称(metric name)可以反映被监控样本的含义（比如，http*request_total - 表示当前系统接收到的 HTTP 请求总量）。指标名称只能由 ASCII 字符、数字、下划线以及冒号组成并必须符合正则表达式`[a-zA-Z*:][a-zA-Z0-9_:]\*`。

  * 标签(label)反映了当前样本的特征维度，通过这些维度 Prometheus 可以对样本数据进行过滤，聚合等。标签的名称只能由 ASCII 字符、数字以及下划线组成并满足正则表达式 `[a-zA-Z_][a-zA-Z0-9_]*`。




每个不同的 `metric_name`和 `label` 组合都称为**时间序列** ，在 Prometheus 的表达式语言中，表达式或子表达式包括以下四种类型之一：

  * 瞬时向量（Instant vector）：一组时间序列，每个时间序列包含单个样本，它们共享相同的时间戳。也就是说，表达式的返回值中只会包含该时间序列中的最新的一个样本值。而相应的这样的表达式称之为瞬时向量表达式。
  * 区间向量（Range vector）：一组时间序列，每个时间序列包含一段时间范围内的样本数据，这些是通过将时间选择器附加到方括号中的瞬时向量（例如[5m]5 分钟）而生成的。
  * 标量（Scalar）：一个简单的数字浮点值。
  * 字符串（String）：一个简单的字符串值。



所有这些指标都是 Prometheus 定期从 metrics 接口那里采集过来的。采集的间隔时间的设置由 `prometheus.yaml` 配置中的 `scrape_interval` 指定。最多抓取间隔为 30 秒，这意味着至少每 30 秒就会有一个带有新时间戳记录的新数据点，这个值可能会更改，也可能不会更改，但是每隔 `scrape_interval` 都会产生一个新的数据点。

## 指标类型

从存储上来讲所有的监控指标 metric 都是相同的，但是在不同的场景下这些 metric 又有一些细微的差异。 例如，在 Node Exporter 返回的样本中指标 `node_load1` 反应的是当前系统的负载状态，随着时间的变化这个指标返回的样本数据是在不断变化的。而指标 `node_cpu_seconds_total` 所获取到的样本数据却不同，它是一个持续增大的值，因为其反应的是 CPU 的累计使用时间，从理论上讲只要系统不关机，这个值是会一直变大。

为了能够帮助用户理解和区分这些不同监控指标之间的差异，Prometheus 定义了 4 种不同的指标类型：Counter（计数器）、Gauge（仪表盘）、Histogram（直方图）、Summary（摘要）。

在 node-exporter 返回的样本数据中，其注释中也包含了该样本的类型。例如：
    
    
    # HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
    # TYPE node_cpu_seconds_total counter
    node_cpu_seconds_total{cpu="cpu0",mode="idle"} 362812.7890625
    

### Counter

`Counter` (只增不减的计数器) 类型的指标其工作方式和计数器一样，只增不减。常见的监控指标，如 `http_requests_total`、`node_cpu_seconds_total` 都是 `Counter` 类型的监控指标。

`Counter` 是一个简单但又强大的工具，例如我们可以在应用程序中记录某些事件发生的次数，通过以时间序列的形式存储这些数据，我们可以轻松的了解该事件产生的速率变化。`PromQL` 内置的聚合操作和函数可以让用户对这些数据进行进一步的分析，例如，通过 `rate()` 函数获取 HTTP 请求量的增长率：
    
    
    rate(http_requests_total[5m])
    

查询当前系统中，访问量前 10 的 HTTP 请求：
    
    
    topk(10, http_requests_total)
    

### Gauge

与 `Counter` 不同，`Gauge`（可增可减的仪表盘）类型的指标侧重于反应系统的当前状态。因此这类指标的样本数据可增可减。常见指标如：`node_memory_MemFree_bytes`（主机当前空闲的内存大小）、`node_memory_MemAvailable_bytes`（可用内存大小）都是 `Gauge` 类型的监控指标。通过 `Gauge` 指标，用户可以直接查看系统的当前状态：
    
    
    node_memory_MemFree_bytes
    

对于 `Gauge` 类型的监控指标，通过 `PromQL` 内置函数 `delta()` 可以获取样本在一段时间范围内的变化情况。例如，计算 CPU 温度在两个小时内的差异：
    
    
    delta(cpu_temp_celsius{host="zeus"}[2h])
    

还可以直接使用 `predict_linear()` 对数据的变化趋势进行预测。例如，预测系统磁盘空间在 4 个小时之后的剩余情况：
    
    
    predict_linear(node_filesystem_free_bytes[1h], 4 * 3600)
    

### Histogram 和 Summary

除了 `Counter` 和 `Gauge` 类型的监控指标以外，Prometheus 还定义了 `Histogram` 和 `Summary` 的指标类型。`Histogram` 和 `Summary` 主用用于统计和分析样本的分布情况。

在大多数情况下人们都倾向于使用某些量化指标的平均值，例如 CPU 的平均使用率、页面的平均响应时间，这种方式也有很明显的问题，以系统 API 调用的平均响应时间为例：如果大多数 API 请求都维持在 100ms 的响应时间范围内，而个别请求的响应时间需要 5s，那么就会导致某些 WEB 页面的响应时间落到**中位数** 上，而这种现象被称为**长尾问题** 。

为了区分是平均的慢还是长尾的慢，最简单的方式就是按照请求延迟的范围进行分组。例如，统计延迟在 0~10ms 之间的请求数有多少而 10~20ms 之间的请求数又有多少。通过这种方式可以快速分析系统慢的原因。`Histogram` 和 `Summary` 都是为了能够解决这样的问题存在的，通过 `Histogram` 和`Summary` 类型的监控指标，我们可以快速了解监控样本的分布情况。

例如，指标 `prometheus_tsdb_wal_fsync_duration_seconds` 的指标类型为 Summary。它记录了 Prometheus Server 中 `wal_fsync` 的处理时间，通过访问 Prometheus Server 的 `/metrics` 地址，可以获取到以下监控样本数据：
    
    
    # HELP prometheus_tsdb_wal_fsync_duration_seconds Duration of WAL fsync.
    # TYPE prometheus_tsdb_wal_fsync_duration_seconds summary
    prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.5"} 0.012352463
    prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.9"} 0.014458005
    prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.99"} 0.017316173
    prometheus_tsdb_wal_fsync_duration_seconds_sum 2.888716127000002
    prometheus_tsdb_wal_fsync_duration_seconds_count 216
    

从上面的样本中可以得知当前 Prometheus Server 进行 `wal_fsync` 操作的总次数为 216 次，耗时 2.888716127000002s。其中中位数（quantile=0.5）的耗时为 0.012352463，9 分位数（quantile=0.9）的耗时为 0.014458005s。

在 Prometheus Server 自身返回的样本数据中，我们还能找到类型为 Histogram 的监控指标`prometheus_tsdb_compaction_chunk_range_seconds_bucket`：
    
    
    # HELP prometheus_tsdb_compaction_chunk_range_seconds Final time range of chunks on their first compaction
    # TYPE prometheus_tsdb_compaction_chunk_range_seconds histogram
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="100"} 71
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="400"} 71
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="1600"} 71
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="6400"} 71
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="25600"} 405
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="102400"} 25690
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="409600"} 71863
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="1.6384e+06"} 115928
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="6.5536e+06"} 2.5687892e+07
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="2.62144e+07"} 2.5687896e+07
    prometheus_tsdb_compaction_chunk_range_seconds_bucket{le="+Inf"} 2.5687896e+07
    prometheus_tsdb_compaction_chunk_range_seconds_sum 4.7728699529576e+13
    prometheus_tsdb_compaction_chunk_range_seconds_count 2.5687896e+07
    

与 `Summary` 类型的指标相似之处在于 `Histogram` 类型的样本同样会反应当前指标的记录的总数(以 `_count` 作为后缀)以及其值的总量（以 `_sum` 作为后缀）。不同在于 `Histogram` 指标直接反应了在不同区间内样本的个数，区间通过标签 le 进行定义。

## 查询

当 Prometheus 采集到监控指标样本数据后，我们就可以通过 PromQL 对监控样本数据进行查询。基本的 Prometheus 查询的结构非常类似于一个 metric 指标，以指标名称开始。

### 查询结构

比如只查询 `node_cpu_seconds_total` 则会返回所有采集节点的所有类型的 CPU 时长数据，当然如果数据量特别特别大的时候，直接在 Grafana 执行该查询操作的时候，则可能导致浏览器崩溃，因为它同时需要渲染的数据点太多。

接下来，可以使用标签进行过滤查询，标签过滤器支持 4 种运算符：

  * `=` 等于
  * `!=` 不等于
  * `=~` 匹配正则表达式
  * `!~` 与正则表达式不匹配



标签过滤器都位于指标名称后面的`{}`内，比如过滤 master 节点的 CPU 使用数据可用如下查询语句：
    
    
    node_cpu_seconds_total{instance="ydzs-master"}
    

正则匹配

PromQL 查询语句中的正则表达式匹配使用 [RE2语法](https://github.com/google/re2/wiki/Syntax)。

此外我们还可以使用多个标签过滤器，以逗号分隔。多个标签过滤器之间是 `AND` 的关系，所以使用多个标签进行过滤，返回的指标数据必须和所有标签过滤器匹配。

例如如下查询语句将返回所有以 `ydzs-`为前缀的节点的并且是 `idle` 模式下面的节点 CPU 使用时长指标：
    
    
    node_cpu_seconds_total{instance=~"ydzs-.*", mode="idle"}
    

### 范围选择器

我们可以通过将[时间范围选择器（[]）](https://prometheus.io/docs/prometheus/latest/querying/basics/#range-vector-selectors)附加到查询语句中，指定为每个返回的区间向量样本值中提取多长的时间范围。每个时间戳的值都是按时间倒序记录在时间序列中的，该值是从时间范围内的时间戳获取的对应的值。

时间范围通过数字来表示，单位可以使用以下其中之一的时间单位：

  * s - 秒
  * m - 分钟
  * h - 小时
  * d - 天
  * w - 周
  * y - 年



比如 `node_cpu_seconds_total{instance="ydzs-master", mode="idle"}` 这个查询语句，如果添加上 `[1m]` 这个时间范围选择器，则我们可以得到如下所示的信息：

![node cpu range vector](https://picdn.youdianzhishi.com/images/20200323153107.png)

可以看到上面的两个时间序列都有 4 个值，这是因为我们 Prometheus 中配置的抓取间隔是 15 秒，所以，我们从图中的 `@` 符号后面的时间戳可以看出，它们之间的间隔基本上就是 15 秒。

但是现在如果我们在 Prometheus 的页面中查询上面的语句，然后切换到 `Graph` 选项卡的时候，则会出现如下所示的错误信息： ![node cpu range vector graph](https://picdn.youdianzhishi.com/images/20200323154950.png)

这是因为现在每一个时间序列中都有多个时间戳多个值，所以没办法渲染，必须是标量或者瞬时向量才可以绘制图形。

不过通常区间向量都会应用一个函数后变成可以绘制的瞬时向量，Prometheus 中对瞬时向量和区间向量有很多操作的[函数](https://prometheus.io/docs/prometheus/latest/querying/functions)，不过对于区间向量来说最常用的函数并不多，使用最频繁的有如下几个函数：

  * `rate()`: 计算整个时间范围内区间向量中时间序列的每秒平均增长率
  * `irate()`: 仅使用时间范围中的**最后两个数据点** 来计算区间向量中时间序列的每秒平均增长率，`irate` 只能用于绘制快速变化的序列，在长期趋势分析或者告警中更推荐使用 `rate` 函数
  * `increase()`: 计算所选时间范围内时间序列的增量，它基本上是速率乘以时间范围选择器中的秒数



我们选择的时间范围持续时间将确定图表的粒度，比如，持续时间 `[1m]` 会给出非常尖锐的图表，从而很难直观的显示出趋势来，看起来像这样：

![1m node cpu rate](https://picdn.youdianzhishi.com/images/20200323160520.png)

对于一个一小时的图表，`[5m]` 显示的图表看上去要更加合适一些，更能显示出 CPU 使用的趋势：

![5m node cpu rate](https://picdn.youdianzhishi.com/images/20200323160708.png)

对于更长的时间跨度，可能需要设置更长的持续时间，以便消除波峰并获得更多的长期趋势图表。我们可以简单比较持续时间为`[5m]` 和 `[30m]` 的一天内的图表：

![5m node cpu rate of 1d](https://picdn.youdianzhishi.com/images/20200323160924.png)

![30m node cpu rate of 1d](https://picdn.youdianzhishi.com/images/20200323161001.png)

有的时候可能想要查看 5 分钟前或者昨天一天的区间内的样本数据，这个时候我们就需要用到位移操作了，位移操作的关键字是 `offset`，比如我们可以查询 30 分钟之前的 master 节点 CPU 的空闲指标数据：
    
    
    node_cpu_seconds_total{instance="ydzs-master", mode="idle"} offset 30m
    

注意

需要注意的是 `offset` 关键字需要紧跟在选择器(`{}`)后面。

同样位移操作也适用于区间向量，比如我们要查询昨天的前 5 分钟的 CPU 空闲增长率：

![5m node cpu rate of 1d offset](https://picdn.youdianzhishi.com/images/20200324092731.png)

### 关联查询

Prometheus 没有提供类似与 SQL 语句的关联查询的概念，但是我们可以通过在 Prometheus 上使用 [运算符](https://prometheus.io/docs/prometheus/latest/querying/operators/) 来组合时间序列，可以应用于多个时间序列或标量值的常规计算、比较和逻辑运算。

注意

如果将运算符应用于两个瞬时向量，则它将仅应用于匹配的时间序列，当且仅当时间序列具有完全相同的标签集的时候，才认为是匹配的。当表达式左侧的每个序列和右侧的一个序列完全匹配的时候，在序列上使用这些运算符才可以实现一对一匹配。

比如如下的两个瞬时向量：
    
    
    node_cpu_seconds_total{instance="ydzs-master", cpu="0", mode="idle"}
    

和
    
    
    node_cpu_seconds_total{instance="ydzs-node1", cpu="0", mode="idle"}
    

如果我们对这两个序列做加法运算来尝试获取 master 和 node1 节点的总的空闲 CPU 时长，则不会返回任何内容了：

![add operator](https://picdn.youdianzhishi.com/images/20200323165746.png)

这是因为这两个时间序列没有完全匹配标签。我们可以使用 `on` 关键字指定只希望在 `mode` 标签上进行匹配，就可以计算出结果来：

![add operator on](https://picdn.youdianzhishi.com/images/20200323165823.png)

需要注意的是新的瞬时向量包含单个序列，其中仅包含 `on` 关键字中指定的标签。

不过在 Prometheus 中还有很多 [聚合操作](https://prometheus.io/docs/prometheus/latest/querying/operators/#aggregation-operators)，所以，如果我们真的想要获取节点的 CPU 总时长，我们完全不用这么操作，使用 `sum` 操作要简单得多：
    
    
    sum(node_cpu_seconds_total{mode="idle"}) by (instance)
    

`on` 关键字只能用于一对一的匹配中，如果是多对一或者一对多的匹配情况下，就不行了，比如我们可以通过 [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 这个工具来获取 Kubernetes 集群的各种状态指标，包括 Pod 的基本信息，比如我们执行如下所示的查询语句：
    
    
    container_cpu_user_seconds_total{namespace="kube-system"} * on (pod) kube_pod_info
    

就会出现 `Error executing query: multiple matches for labels: many-to-one matching must be explicit (group_left/group_right)` 这样的错误提示，这是因为左侧的序列数据在同一个 Pod 上面有可能会有多条时间序列，所以不能简单通过 `on (pod)` 来进行查询。

要解决这个问题，我们可以使用 `group_left` 或`group_right` 关键字。这两个关键字将匹配分别转换为**多对一** 或**一对多** 匹配。左侧和右侧表示基数较高的一侧。因此，`group_left` 意味着左侧的多个序列可以与右侧的单个序列匹配。结果是，返回的瞬时向量包含基数较高的一侧的所有标签，即使它们与右侧的任何标签都不匹配。

例如如下所示的查询语句就可以正常获取到结果，而且获取到的时间序列数据包含所有的标签:
    
    
    container_cpu_user_seconds_total{namespace="kube-system"} * on (pod) group_left() kube_pod_info
    

### 瞬时向量和标量结合

此外我们还可以将瞬时向量和标量值相结合，这个很简单，就是简单的数学计算，比如：
    
    
    node_cpu_seconds_total{instance="ydzs-master"} * 10
    

会为瞬时向量中每个序列的每个值都剩以 10。这对于计算比率和百分比得时候非常有用。

  * 除了 `*` 之外，其他常用的算数运算符当然也支持：`+`、`-`、`*`、`/`、`%`、`^`。
  * 还有其他的比较运算符：`==`、`!=`、`>`、`<`、`>=`、`<=`。
  * 逻辑运算符：`and`、`or`、`unless`，不过逻辑运算符只能用于瞬时向量之间。



除了这些关于 `PromQL` 最基本的知识点之外，还有很多相关的使用方法，可以参考官网相关介绍：<https://prometheus.io/docs/prometheus/latest/querying/basics/>。
