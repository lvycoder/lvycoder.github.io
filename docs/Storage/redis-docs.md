## **关系型数据库与非关系型数据库**

数据库按照其结构可以分为关系型数据库与其他数据库，而这些其他数据库我们将统称为NoSQL非关系型数据库。

### **扫盲知识**

1. 关系型数据库
关系型数据库是一个结构化的数据库，创建在关系模型的基础上，一般面向记录，他借助与集合代数等数学概念和方法来处理数据库中的数据，关系模型是二维表格模型，因而一个关系型数据库就是由二维表及其之间的联系组成的一个数据一个数据组织。现实世界中，各种实体与实体之间的各种联系都可以用关系模型来表示。SQL语句（Structured Ouery Lanage，结构化查询语言）就是一种基于关系型数据库的语言，用于执行对关系型数据库中数据的检索和操作。主流的关系型数据库（mysql、oracle、sql server、Microsoft Access、DB2）等。

2. 非关系型数据库
NoSQL（Not Only SQL）其意思是不仅仅是SQL，是非关系型数据库的总称，主流的非关系型数据库（Memcached、Redis、MongoDB、Hbase、CouhDB等以上的这些数据库它们的存储方式，存储结构，以及使用场景是完全不同的，所以我们认为他是一个非关系型数据库的集合，而不是像关系型数据库一样是一个统称。换言之，主流关系型数据库以外的数据库都是非关系型数据库，NoSQL数据库凭借着其非关系型，分布式，开源的横向扩展等优势，被认为是下一代数据库产品）。




### **非关系型数据库产生背景**


关系型数据库已经诞生很久了，而且我们一直在使用，没有什么问题，面对这样的情况，为什么还会产生非关系型数据库？下面我们就来介绍一下非关系型数据库产生的背景。

  随着Web 2.0网站的兴起，关系型数据库在应对Web 2.0网站，特别是海量数据库和高并发的SNS（Social Networking Services，即社交网络服务）类型的Web 2.0纯动态网站时，暴露出很多难以解决的问题，例如以下三高问题。

1）High performance——对数据库高并发读写需求

  Web 2.0网站会根据用户的个性化信息来实时生成动态页面和提供动态信息，因为，无法使用动态页面静态化技术，所以数据库的并发负载非常高，一般会达到10000次/s以上的读写请求。关系型数据库对于上万次的查询请求还是可以勉强支撑的。当出现上万次的写数据请求时，硬盘I/O就已经无法承受了，对于普通的BBS网站，往往也会存在高并发的读数据请求，如明星鹿晗在微博上公布恋情，结果因为流量过大而引发微博瘫痪。

2）Huge storage——对海量数据库高效存储与访问需求

  类似于Facebook、Friendfeed这样的SNS网站，每天会产生大量的用户动态信息，例如Friendfeed一个月就会产生2.5亿条用户动态信息，对于关系型数据库来说，在一个包含2.5亿条记录的表中执行SQL查询，效率是非常低的。

3）High Scalability && High Availability——对数据库高扩展性与高可用性需求

  在Web架构中，数据库是最难进行横向扩展的，当应用系统的用户量与访问量与日俱增时，数据库是没办法像Web服务一样，简单地通过添加硬件和服务节点其性能和负载均衡能力的，尤其对于一些需要24h对外提供服务的网站来说，数据库的升级与扩展性往往伴随着停机维护与数据迁移，其工作量是非常庞大的。

  关系型数据库和非关系型数据库都有各自的特点与应用场景，再者的紧密结合将会给Web 2.0的数据库发展带来新的思路，让关系型数据库关注在关系上，非关系数据库关注在存储上。


### **Redis 介绍**

Redis是一个开源的，使用C语言编写，支持网络，可基于内存工作亦可持久化（AOF，RDB ）的日志型，key-values（键值对）数据库，一个速度极快的非关系性数据库，也就是我们所说的NoSQL数据库，他可以存储（key）与5种不同类型的值（value）之间的映射（mapping），可以将存储在内存的键值对数持久化到硬盘，可以使用复制特性来扩展读性能，还可以使用客户端分片来扩展性能，并且它还提供了多种语言的API。
Redis的所有数据都是保存在内存中，然后不定期的通过异步方式保存到磁盘上（这个称为半持久化RDB）；也可以把每一次数据变化都写入到一个append onlyfile（AOF）里面（这称为“全持久化”）。
全持久化与半持久化的方式在工作中适当的使用，在如今的生产环境中，如果使用全持久化的方式可能会造成append onlyfile的文件过大，如果是半持久化的话又没有办法保证数据的安全性，所以希望大家适当的使用。



### **Redis的工作原理**



Redis服务器程序是一个单进程模型，也就是说在一台服务器上可以开启多个redis进程（多实例），而redis的实际处理速度则完全依靠于主进程的执行速率，若在服务器上只运行一个redis进程，当多个客户端同时访问时，服务器处理能力会有一定程度的下降，若在一个服务器上开启多个redis进程，redis在提高并发处理能力的同时也会给CPU造成很大的压力，所以在实际生产环境中，结合实际服务器环境来决定如何使用。



### Redis 的优点

- 具有极高的数据读写速度：数据读取速度最高可达11万次/s，数据写入速度最高可达8万1千次/s
- 支持丰富的数据类型，支持丰富的数据类型不仅支持key-values数据类型，还支持Strings，Lists，Hashes，Sets，及Ordered Sets等数据类型操作
- 支持数据的持久化，在这一点上redis远远强于memcached，redis可以将数据保存到磁盘中，重启后还可以继续加载使用
- 原子性 redis的所有操作都是原子性的
- 支持数据备份及master-slave模式的数据备份



### **helm 部署 redis**

在云原生环境中部署 Redis 集群，我们通常会使用 Kubernetes，它是一个开源的容器编排平台，用于自动化应用程序容器的部署、扩展和管理。对于 Redis，我们可以使用 Helm，这是一个 Kubernetes 的包管理器，可以帮助我们更容易地管理和部署应用。

以下是在 Kubernetes 中使用 Helm 部署 Redis 集群的两种方法：



- 集群方式
- 哨兵方式


以下是一个小 demo 的例子:

1. **安装 Helm**：首先，如果你还没有安装 Helm，你需要在你的机器上安装它。你可以从 Helm 的 GitHub 仓库下载最新的 Helm 二进制包并安装。

2. **添加 Helm 仓库**：Bitnami 维护了一个包含了许多常见应用（包括 Redis）的 Helm 仓库。你可以使用以下命令添加这个仓库：

   

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-redis-cluster bitnami/redis --set cluster.enabled=true,cluster.nodes=3,persistence.enabled=true,persistence.size=1Gi
```
这个命令将部署一个包含 3 个节点的 Redis 集群，并为每个节点启用了 1Gi 的持久化存储。

**验证部署**：最后，你可以使用以下命令检查 Redis 集群的状态：


如果一切顺利，你应该可以看到你的 Redis pods 在运行。

这只是一个最基本的示例。在实际环境中，你可能需要根据你的具体需求调整各种参数，例如节点数、存储大小、密码等。你可以在 Bitnami 的 Redis Helm chart 文档中找到更多的配置选项。

此外，你也需要考虑如何处理数据持久化、高可用性、备份和恢复等问题。例如，你可能需要配置 Kubernetes 的 Persistent Volumes 和 Persistent Volume Claims 来处理数据持久化，配置 Redis 的主从复制和哨兵模式来实现高可用性，定期备份 Redis 数据以防数据丢失，等等。




### **生产环境部署**

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