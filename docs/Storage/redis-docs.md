## **helm 部署 redis**

在云原生环境中部署 Redis 集群，我们通常会使用 Kubernetes，它是一个开源的容器编排平台，用于自动化应用程序容器的部署、扩展和管理。对于 Redis，我们可以使用 Helm，这是一个 Kubernetes 的包管理器，可以帮助我们更容易地管理和部署应用。

以下是在 Kubernetes 中使用 Helm 部署 Redis 集群的两种方法：
- 集群方式
- 哨兵方式


以下是一个小 demo 的例子:

1. **安装 Helm**：首先，如果你还没有安装 Helm，你需要在你的机器上安装它。你可以从 Helm 的 GitHub 仓库下载最新的 Helm 二进制包并安装。

2. **添加 Helm 仓库**：Bitnami 维护了一个包含了许多常见应用（包括 Redis）的 Helm 仓库。你可以使用以下命令添加这个仓库：

   ```
   helm repo add bitnami https://charts.bitnami.com/bitnami
   ```

3. **更新 Helm 仓库**：添加新的 Helm 仓库后，你需要更新 Helm 仓库以获取最新的包信息：

   ```
   helm repo update
   ```

4. **部署 Redis 集群**：现在，你可以使用 Helm 部署 Redis 集群了。以下是一个基本的命令：

   ```
   helm install my-redis-cluster bitnami/redis --set cluster.enabled=true,cluster.nodes=3,persistence.enabled=true,persistence.size=1Gi
   ```

   这个命令将部署一个包含 3 个节点的 Redis 集群，并为每个节点启用了 1Gi 的持久化存储。

5. **验证部署**：最后，你可以使用以下命令检查 Redis 集群的状态：

   ```
   kubectl get pods
   ```

   如果一切顺利，你应该可以看到你的 Redis pods 在运行。

这只是一个最基本的示例。在实际环境中，你可能需要根据你的具体需求调整各种参数，例如节点数、存储大小、密码等。你可以在 Bitnami 的 Redis Helm chart 文档中找到更多的配置选项。

此外，你也需要考虑如何处理数据持久化、高可用性、备份和恢复等问题。例如，你可能需要配置 Kubernetes 的 Persistent Volumes 和 Persistent Volume Claims 来处理数据持久化，配置 Redis 的主从复制和哨兵模式来实现高可用性，定期备份 Redis 数据以防数据丢失，等等。







- 添加Helm chart
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

```

- 查询 Redis 资源
```
$ helm search repo redis 
NAME                                          	CHART VERSION	APP VERSION	DESCRIPTION
bitnami/redis                                 	17.15.2      	7.0.12     	Redis(R) is an open source, advanced key-value ...
bitnami/redis-cluster                         	8.6.12       	7.0.12     	Redis(R) is an open source, scalable, distribut...
prometheus-community/prometheus-redis-exporter	5.5.0        	v1.44.0    	Prometheus exporter for Redis metrics
stable/prometheus-redis-exporter              	3.5.1        	1.3.4      	DEPRECATED Prometheus exporter for Redis metrics
stable/redis                                  	10.5.7       	5.0.7      	DEPRECATED Open source, advanced key-value stor...
stable/redis-ha                               	4.4.6        	5.0.6      	DEPRECATED - Highly available Kubernetes implem...
ucloud-operator/redis-cluster-operator        	0.1.0        	0.1.0      	A Helm chart for Redis cluster operator deployment
stable/sensu                                  	0.2.5        	0.28       	DEPRECATED Sensu monitoring framework backed by...
```

- 下载 chart 包
```
$ helm search repo redis --versions
$ helm pull bitnami/redis --version 17.15.2
```