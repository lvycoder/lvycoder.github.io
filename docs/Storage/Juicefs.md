## **Juicefs 存储介绍**

**JuiceFS** 是一款面向云原生设计的高性能分布式文件系统，在 Apache 2.0 开源协议下发布。提供完备的 [POSIX](https://en.wikipedia.org/wiki/POSIX) 兼容性，可将几乎所有对象存储接入本地作为海量本地磁盘使用，亦可同时在跨平台、跨地区的不同主机上挂载读写。

JuiceFS 采用「数据」与「元数据」分离存储的架构，从而实现文件系统的分布式设计。文件数据本身会被切分保存在[对象存储](../reference/how_to_set_up_object_storage.md#supported-object-storage)（例如 Amazon S3），而元数据则可以保存在 Redis、MySQL、TiKV、SQLite 等多种[数据库](../reference/how_to_set_up_metadata_engine.md)中，你可以根据场景与性能要求进行选择。

JuiceFS 提供了丰富的 API，适用于各种形式数据的管理、分析、归档、备份，可以在不修改代码的前提下无缝对接大数据、机器学习、人工智能等应用平台，为其提供海量、弹性、低价的高性能存储。运维人员不用再为可用性、灾难恢复、监控、扩容等工作烦恼，专注于业务开发，提升研发效率。同时运维细节的简化，对 DevOps 极其友好。

<div className="video-container">
  <iframe src="//player.bilibili.com/player.html?aid=931107196&bvid=BV1HK4y197va&cid=350876578&page=1&autoplay=0" width="100%" height="360" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>
</div>


## **核心特性**

1. **POSIX 兼容**：像本地文件系统一样使用，无缝对接已有应用，无业务侵入性；
2. **HDFS 兼容**：完整兼容 [HDFS API](../deployment/hadoop_java_sdk.md)，提供更强的元数据性能；
3. **S3 兼容**：提供 [S3 网关](../deployment/s3_gateway.md) 实现 S3 协议兼容的访问接口；
4. **云原生**：通过 [Kubernetes CSI 驱动](../deployment/how_to_use_on_kubernetes.md) 轻松地在 Kubernetes 中使用 JuiceFS；
5. **分布式设计**：同一文件系统可在上千台服务器同时挂载，高性能并发读写，共享数据；
6. **强一致性**：确认的文件修改会在所有服务器上立即可见，保证强一致性；
7. **强悍性能**：毫秒级延迟，近乎无限的吞吐量（取决于对象存储规模），查看[性能测试结果](../benchmark/benchmark.md)；
8. **数据安全**：支持传输中加密（encryption in transit）和静态加密（encryption at rest），[查看详情](../security/encrypt.md)；
9. **文件锁**：支持 BSD 锁（flock）和 POSIX 锁（fcntl）；
10. **数据压缩**：支持 [LZ4](https://lz4.github.io/lz4) 和 [Zstandard](https://facebook.github.io/zstd) 压缩算法，节省存储空间。


## **应用场景**

JuiceFS 为海量数据存储设计，可以作为很多分布式文件系统和网络文件系统的替代，特别是以下场景：

- 大数据分析：HDFS 兼容；与主流计算引擎（Spark、Presto、Hive 等）无缝衔接；无限扩展的存储空间；运维成本几乎为 0；性能远好于直接对接对象存储。

- 机器学习：POSIX 兼容，可以支持所有机器学习、深度学习框架；方便的文件共享还能提升团队管理、使用数据效率。
Kubernetes：JuiceFS 支持 Kubernetes CSI；为容器提供解耦的文件存储，令应用服务可以无状态化；方便地在容器间共享数据。

- 共享工作区：可以在任意主机挂载；没有客户端并发读写限制；POSIX 兼容已有的数据流和脚本操作。
数据备份：在无限平滑扩展的存储空间备份各种数据，结合共享挂载功能，可以将多主机数据汇总至一处，做统一备份。



## **技术架构**

![](https://pic.imgdb.cn/item/64ddc7b6661c6c8e542ebab0.jpg)

JuiceFS 文件系统由三个部分组成：

**JuiceFS 客户端（Client）**：所有文件读写，以及碎片合并、回收站文件过期删除等后台任务，均在客户端中发生。客户端需要同时与对象存储和元数据引擎打交道。客户端支持多种接入方式：

- 通过 **FUSE**，JuiceFS 文件系统能够以 POSIX 兼容的方式挂载到服务器，将海量云端存储直接当做本地存储来使用。
- 通过 **Hadoop Java SDK**，JuiceFS 文件系统能够直接替代 HDFS，为 Hadoop 提供低成本的海量存储。
- 通过 **Kubernetes CSI 驱动**，JuiceFS 文件系统能够直接为 Kubernetes 提供海量存储。
- 通过 **S3 网关**，使用 S3 作为存储层的应用可直接接入，同时可使用 AWS CLI、s3cmd、MinIO client 等工具访问 JuiceFS 文件系统。
- 通过 **WebDAV 服务**，以 HTTP 协议，以类似 RESTful API 的方式接入 JuiceFS 并直接操作其中的文件。

**数据存储（Data Storage）**：文件将会被切分上传至对象存储服务。JuiceFS 支持几乎所有的公有云对象存储，同时也支持 OpenStack Swift、Ceph、MinIO 等私有化的对象存储。

**元数据引擎（Metadata Engine）**：用于存储文件元数据（metadata），包含以下内容：

- 常规文件系统的元数据：文件名、文件大小、权限信息、创建修改时间、目录结构、文件属性、符号链接、文件锁等。
- 文件数据的索引：文件的数据分配和引用计数、客户端会话等。


## **环境部署**

!!! info "环境要求"
    - 这里做 dome 实验,所以可用 k3s 作为实验环境,利用k3s自带的local-path,作为 redis-cluster的块存储,后端使用 minio 作为 juicefs 对接的s3存储

**部署方式:**

- 方式一: [在 K3s 上使用 JuiceFS]( https://juicefs.com/docs/zh/community/juicefs_on_k3s) (测试可以使用这种方式,比较简单)
- 方式二: [官方推荐helm方式部署](https://juicefs.com/docs/zh/csi/getting_started/) (生产环境强烈推荐这种)
- 优化方法:[可以参考我写的一个 pr 对已经安装的 juicefs 进行优化](https://github.com/barry-boy/barry-boy.github.io/issues/62)



## **Juicefs升级**

可以参考 juicefs 官方推荐 helm 方式来升级,文章参考:https://juicefs.com/docs/zh/csi/upgrade-csi-driver
```
helm repo update
helm upgrade juicefs-csi-driver juicefs/juicefs-csi-driver -n kube-system -f ./values.yaml

我是从 1.1 beta 版本升级,其中 values 中只需要修改一个镜像版本即可.

image:
  repository: juicedata/juicefs-csi-driver
  tag: "v0.22.0" # 修改为最新版即可
  pullPolicy: ""
```


### **文章参考:**

- [juicefs 官方文档](https://juicefs.com/docs/zh/csi/getting_started/)
- [redis cluster 文章](https://github.com/bitnami/charts/tree/main/bitnami/redis-cluster)
- [minio 官方文档](https://min.io/docs/minio/kubernetes/gke/index.html)



