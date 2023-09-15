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



### **Redis 的优点**

- 具有极高的数据读写速度：数据读取速度最高可达11万次/s，数据写入速度最高可达8万1千次/s
- 支持丰富的数据类型，支持丰富的数据类型不仅支持key-values数据类型，还支持Strings，Lists，Hashes，Sets，及Ordered Sets等数据类型操作
- 支持数据的持久化，在这一点上redis远远强于memcached，redis可以将数据保存到磁盘中，重启后还可以继续加载使用
- 原子性 redis的所有操作都是原子性的
- 支持数据备份及master-slave模式的数据备份



### ** Helm 部署 redis**

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

!!! warning "温馨提示"
    stable这种方案已经不维护了，所以不考虑使用这种方式，这边主要以bitnami来讲。这里不推荐使用源码部署

- 下载 chart 包

```
$ helm search repo redis --versions
$ helm pull bitnami/redis --version 17.15.2
```

由于redis集群存储方式的特殊性，这里考虑使用的方案的：local-path-provisioner

- 官方地址: https://github.com/rancher/local-path-provisioner

考虑的理由: 

    1. 脱离中心存储，我们的之前数据库主要存储在ceph中，一旦ceph出现问题，mysql有极大的可能无法启动。
    2. 将mysql的数据分离出来有利于减少中心存储的压力。
    3. local-path-provisioner将本地目录作为最后数据存储的路径。因此我们在多个节点添加一块数据盘+部署高可用的哨兵集群并限制于该节点。



### **配置文件介绍**

```shell
1. Redis默认不是以守护进程的方式运行，可以通过该配置项修改，使用yes启用守护进程
daemonize yes
2. 当Redis以守护进程方式运行时，Redis默认会把pid写入/var/run/redis.pid文件，可以通过pidfile指定
pidfile /var/run/redis_6379.pid 
3. 指定Redis监听端口，默认端口为6379 
port 6379
4. 绑定的主机地址
bind 0.0.0.0
5.当客户端闲置多长时间后关闭连接，如果指定为0，表示关闭该功能
timeout 300
6. 指定日志记录级别，Redis总共支持四个级别：debug、verbose、notice、warning，默认为verbose
loglevel verbose
7. 日志记录方式，默认为标准输出，如果配置Redis为守护进程方式运行，而这里又配置为日志记录方式为标准输出，则日志将会发送给/dev/null
logfile /var/log/redis_6379.log 
8. 设置数据库的数量，默认数据库为0，可以使用SELECT <dbid>命令在连接上指定数据库id
databases 16
9. 指定在多长时间内，有多少次更新操作，就将数据同步到数据文件，可以多个条件配合
save <seconds> <changes>
Redis默认配置文件中提供了三个条件：
    save 900 1
    save 300 10
    save 60 10000
    分别表示900秒（15分钟）内有1个更改，300秒（5分钟）内有10个更改以及60秒内有10000个更改。
10. 指定存储至本地数据库时是否压缩数据，默认为yes，Redis采用LZF压缩，如果为了节省CPU时间，可以关闭该选项，但会导致数据库文件变的巨大
rdbcompression yes
11. 指定本地数据库文件名，默认值为dump.rdb
dbfilename dump.rdb
12. 指定本地数据库存放目录
dir /var/lib/redis/6379 
13. 设置当本机为slave服务时，设置master服务的IP地址及端口，在Redis启动时，它会自动从master进行数据同步
slaveof <masterip> <masterport>
14. 当master服务设置了密码保护时，slave服务连接master的密码
masterauth <master-password>
15. 设置Redis连接密码，如果配置了连接密码，客户端在连接Redis时需要通过AUTH <password>命令提供密码，默认关闭
requirepass foobared
16. 设置同一时间最大客户端连接数，默认无限制，Redis可以同时打开的客户端连接数为Redis进程可以打开的最大文件描述符数，如果设置 maxclients 0，表示不作限制。当客户端连接数到达限制时，Redis会关闭新的连接并向客户端返回max number of clients reached错误信息
maxclients 128
17. 指定Redis最大内存限制，Redis在启动时会把数据加载到内存中，达到最大内存后，Redis会先尝试清除已到期或即将到期的Key，当此方法处理 后，仍然到达最大内存设置，将无法再进行写入操作，但仍然可以进行读取操作。Redis新的vm机制，会把Key存放内存，Value会存放在swap区
maxmemory <bytes>
18. 指定是否在每次更新操作后进行日志记录，Redis在默认情况下是异步的把数据写入磁盘，如果不开启，可能会在断电时导致一段时间内的数据丢失。因为 redis本身同步数据文件是按上面save条件来同步的，所以有的数据会在一段时间内只存在于内存中。默认为no
appendonly yes
19. 指定更新日志文件名，默认为appendonly.aof
appendfilename appendonly.aof
20. 指定更新日志条件，共有3个可选值： 
no：表示等操作系统进行数据缓存同步到磁盘（快） 
always：表示每次更新操作后手动调用fsync()将数据写到磁盘（慢，安全） 
everysec：表示每秒同步一次（折衷，默认值）
appendfsync everysec

21. 指定是否启用虚拟内存机制，默认值为no，简单的介绍一下，VM机制将数据分页存放，由Redis将访问量较少的页即冷数据swap到磁盘上，访问多的页面由磁盘自动换出到内存中（在后面的文章我会仔细分析Redis的VM机制）
vm-enabled no
22. 虚拟内存文件路径，默认值为/tmp/redis.swap，不可多个Redis实例共享
vm-swap-file /tmp/redis.swap
23. 将所有大于vm-max-memory的数据存入虚拟内存,无论vm-max-memory设置多小,所有索引数据都是内存存储的(Redis的索引数据 就是keys),也就是说,当vm-max-memory设置为0的时候,其实是所有value都存在于磁盘。默认值为0
vm-max-memory 0
24. Redis swap文件分成了很多的page，一个对象可以保存在多个page上面，但一个page上不能被多个对象共享，vm-page-size是要根据存储的 数据大小来设定的，作者建议如果存储很多小对象，page大小最好设置为32或者64bytes；如果存储很大大对象，则可以使用更大的page，如果不 确定，就使用默认值
vm-page-size 32
25. 设置swap文件中的page数量，由于页表（一种表示页面空闲或使用的bitmap）是在放在内存中的，，在磁盘上每8个pages将消耗1byte的内存。
vm-pages 134217728
26. 设置访问swap文件的线程数,最好不要超过机器的核数,如果设置为0,那么所有对swap文件的操作都是串行的，可能会造成比较长时间的延迟。默认值为4
vm-max-threads 4
27. 设置在向客户端应答时，是否把较小的包合并为一个包发送，默认为开启
glueoutputbuf yes
28. 指定在超过一定的数量或者最大的元素超过某一临界值时，采用一种特殊的哈希算法
hash-max-zipmap-entries 64
hash-max-zipmap-value 512
29. 指定是否激活重置哈希，默认为开启（后面在介绍Redis的哈希算法时具体介绍）
activerehashing yes
30. 指定包含其它的配置文件，可以在同一主机上多个Redis实例之间使用同一份配置文件，而同时各个实例又拥有自己的特定配置文件
include /path/to/local.conf
```



当然以上的配置参数不需要都了解，看情况需要什么配置什么即可。我们之后使用helm部署大部分的参数也已经都有了。redis中比较重要的就是他的持久化。后续会列一下他持久化的的方式。



### **redis-cli 用法**

```shell
redis-cli -h 远程连接主机 -p 指定端口 -a 指定密码
```

注：若未设置数据库密码 -a选项可以忽略 退出数据库操作环境可以执行 quit 或 exit 就可以返回到原来的shell文件

```
[root@localhost ~]# redis-cli 
127.0.0.1:6379> ping
PONG								# 执行ping命令可以检测Redis服务是否启动
```



### **redis-benchmark测试工具**

Redis-benchmark是redis官方自带的redis性能测试工具，可以有效的测试redis服务的性能。



语法：

```
redis-benchmark [option] [option value]
```

参数：

```
-h：指定服务器名
-p：指定服务器端口
-s：指定服务器socket
-c：指定并发连接数
-n：指定请求连接数
-d：以字节（B）的形式指定 SET/GET值的数据大小
-k：1=keep alive 0=reconnect
-r:SET/GET/INCR 使用随机key，SADD使用的随机值
-P：通过管道传输<numreq>请求
-q：强制退出 redis。仅显示 query/sec值
--csv :以CSV格式输出
-l ： 生成循环，永久执行测试
-t ： 仅运行以逗号分隔的测试命令列表
-I :idle模式。仅打开/v个idle连接并等待
```

### **Redis-benchmark应用实例**

- 测试并发数为10请求连接数为100000个请求的性能

```
[root@localhost redis]# redis-benchmark -h localhost -p 6379 -c 10 -n 100000

Summary:
  throughput summary: 2584.25 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.378     0.448     2.719     7.159    16.607   389.375
```

- 测试存取大小为100B的数据包时redis的性能

```
[root@localhost ~]# redis-benchmark -h localhost -p 6379 -q -d 100

PING_INLINE: 9354.54 requests per second, p50=2.543 msec
PING_MBULK: 9018.76 requests per second, p50=2.567 msec
SET: 6365.78 requests per second, p50=5.183 msec
GET: 8983.11 requests per second, p50=2.639 msec
INCR: 6784.26 requests per second, p50=4.711 msec
LPUSH: 6266.84 requests per second, p50=5.511 msec
RPUSH: 6391.41 requests per second, p50=5.359 msec
LPOP: 6735.37 requests per second, p50=4.911 msec
RPOP: 7187.01 requests per second, p50=4.935 msec
SADD: 9295.41 requests per second, p50=2.551 msec
HSET: 6427.15 requests per second, p50=5.359 msec
SPOP: 9106.64 requests per second, p50=2.527 msec
ZADD: 8525.88 requests per second, p50=2.663 msec
ZPOPMIN: 8797.40 requests per second, p50=2.559 msec
LPUSH (needed to benchmark LRANGE): 6059.87 requests per second, p50=5.615 msec
LRANGE_100 (first 100 elements): 4113.20 requests per second, p50=5.695 msec
LRANGE_300 (first 300 elements): 1667.83 requests per second, p50=13.879 msec
LRANGE_500 (first 500 elements): 1051.38 requests per second, p50=15.783 msec
LRANGE_600 (first 600 elements): 951.19 requests per second, p50=18.767 msec
MSET (10 keys): 3831.71 requests per second, p50=9.711 msec
```

参数说明：

```
你运行的是 Redis 的性能基准测试，测试了各种常见的 Redis 操作的性能。以下是对这些结果的解读：

- `PING_INLINE` 和 `PING_MBULK` 是检测 Redis 服务器是否在线的操作。在这次测试中，它们的吞吐量分别是 9354.54 和 9018.76 请求/秒，p50 延迟分别是 2.543 和 2.567 毫秒。

- `SET`、`GET` 和 `INCR` 是常见的键值操作。它们的吞吐量分别是 6365.78、8983.11 和 6784.26 请求/秒，p50 延迟分别是 5.183、2.639 和 4.711 毫秒。

- `LPUSH`、`RPUSH`、`LPOP` 和 `RPOP` 是列表操作。它们的吞吐量分别是 6266.84、6391.41、6735.37 和 7187.01 请求/秒，p50 延迟分别是 5.511、5.359、4.911 和 4.935 毫秒。

- `SADD`、`HSET` 和 `SPOP` 是集合和哈希操作。它们的吞吐量分别是 9295.41、6427.15 和 9106.64 请求/秒，p50 延迟分别是 2.551、5.359 和 2.527 毫秒。

- `ZADD` 和 `ZPOPMIN` 是有序集合操作。它们的吞吐量分别是 8525.88 和 8797.40 请求/秒，p50 延迟分别是 2.663 和 2.559 毫秒。

- `LRANGE` 是获取列表的一部分的操作。这个操作的性能取决于你获取的元素数量。在这次测试中，获取前 100、300、500 和 600 个元素的吞吐量分别是 4113.20、1667.83、1051.38 和 951.19 请求/秒，p50 延迟分别是 5.695、13.879、15.783 和 18.767 毫秒。

- `MSET` 是一次设置多个键值的操作。在这次测试中，设置 10 个键值的吞吐量是 3831.71 请求/秒，p50 延迟是 9.711 毫秒。

这些结果可以帮助你了解在你的硬件和配置下，Redis 对于各种操作的性能表现。如果你发现某些操作的性能不佳，你可以尝试调整 Redis 的配置或升级你的硬件来改善性能。
```

- 测试执行set,lpush 操作时的性能

```
[root@localhost ~]# redis-benchmark -h localhost -p 6379 -t set,lpush -n 100000 -q
```


### **Redis数据库常用命令**

Redis数据库采用key-values（键值对）的数据存储形式，所使用的命令是set与get命令。

- set：用于redis数据库中存放数据 命令格式为 set key value
- get: 用于redis数据库中获取数据 命令格式为 get key

```
[root@localhost ~]# redis-cli
127.0.0.1:6379> ping       # 测试redis服务是否启动
PONG
127.0.0.1:6379> info		   # 查看详细信息
# Server
redis_version:4.0.10
……#省略部分信息
# CPU
used_cpu_sys:232.48

# Cluster
cluster_enabled:0

# Keyspace
db0:keys=4,expires=0,avg_ttl=0
```

- 内存使用量

```
> INFO memory
used_memory: 19167628056
used_memory_human: 17.85G
used_memory_rss: 20684886016
used_memory_rss_human: 19.26G
...
used_memory_overhead: 5727954464
...
used_memory_dataset: 13439673592
used_memory_dataset_perc: 70.12%
```

其中 used_memory_rss 是 Redis 实际使用的总内存大小，这里既包含了存储在 Redis 中的数据大小（也就是上面的 used_memory_dataset），也包含了一些 Redis 的系统开销（也就是上面的 used_memory_overhead）。


- set，get应用案例

```
127.0.0.1:6379> set name zhangsan     		# 设置键值列表为name 键值为zhangsan
OK  
127.0.0.1:6379> get name					# 获取name的键值
"zhangsan"
```

- key相关命令

在使用keys命令可以取符合规则的键值列表，通常情况可以结合*，？等选项来使用
？：表示任意一位数据
*：表示任意数据

```
127.0.0.1:6379> set name zhangsan
OK
127.0.0.1:6379> get name
"zhangsan"
127.0.0.1:6379> set k1 1
OK
127.0.0.1:6379> set k2 2
OK
127.0.0.1:6379> set k3 3
OK
127.0.0.1:6379> set s1 4
OK
127.0.0.1:6379> set v55 5
OK
```

- 通过keys获取键值列表信息

```
127.0.0.1:6379> keys *
1) "name"
2) "mylist"
3) "key3"
4) "myhash"
5) "key1"
6) "key2"
7) "key:__rand_int__"
8) "key4"
9) "counter:__rand_int__"


127.0.0.1:6379> KEYS key? # ？表示k后面的任意一个字符 及匹配任何一个以k开头的键列表后面只有一位的
1) "key3"
2) "key1"
3) "key2"
4) "key4"
127.0.0.1:6379>

127.0.0.1:6379> KEYS key* # * 任意及匹配任何一个以key开头的键列表
1) "key3"
2) "key1"
3) "key2"
4) "key:__rand_int__"
5) "key4"
```

- exists命令
作用：用来判断键值是否存在

```
127.0.0.1:6379> exists name   			# 判断name键是否存在
(integer) 1							# 返回1表示存在
127.0.0.1:6379> exists name1			
(integer) 0							# 返回0表示不存在
```


- del 删除命令

```
127.0.0.1:6379> get name
"zhangsan"
127.0.0.1:6379> del name
(integer) 1
127.0.0.1:6379> get name
(nil)
```

- Type 命令

作用：使用type命令可以获取key对应的value值的类型

```
127.0.0.1:6379> type key1
string
```

- rename命令 (对已有的key进行重命名)
- 命令格式：rename 源key 目标key

!!! warning "温馨提示"
    注意：使用rename命令进行重命名时，无论目标key是否存在都会进行重命名，在实际使用过程中建议先使用exists查看目标key是否存在，再决定是否执行rename命令，以免覆盖重要的数据。

```
127.0.0.1:6379> get key1
"1"
127.0.0.1:6379> rename key1 name
OK
127.0.0.1:6379> get name
"1"
```

- dbsize命令(作用：查看当前数据库中key的数目)

```
127.0.0.1:6379> keys *
1) "name"
2) "mylist"
3) "key3"
4) "myhash"
5) "key2"
6) "key:__rand_int__"
7) "key4"
8) "counter:__rand_int__"

127.0.0.1:6379> dbsize
(integer) 8
```

### **多数据库常用命令**

1. 多数据库之间切换

Redis支持多数据库，redis在默认没有任何改动的情况下包含16个数据库，数据库的名称是使用数值0~15来依次命名的，而我们通过redis-cli打开的是默认的第一个库其显示为“<ip地址：6379>”的形式,通过select命令进行切换后 其格式会变为 “<ip地址：6379[n]>”。
n 表示select后面的数字

```
127.0.0.1:6379> select 5       
OK
127.0.0.1:6379[5]> select 15
OK
127.0.0.1:6379[15]> select 16				# 切换为16时报错
(error) ERR DB index is out of range	# 超出范围
127.0.0.1:6379[15]> select 0
OK
```

### **清除数据库**

Redis清除数据库一般分为两部分

- 清除当前数据库：flushdb
- 清除所有数据库文件：flushall 

```
127.0.0.1:6379> select 1
OK
127.0.0.1:6379[1]> flushdb
OK
127.0.0.1:6379[1]> keys *
(empty list or set)
127.0.0.1:6379[1]> select 0
OK
127.0.0.1:6379> keys *
1) "counter:__rand_int__"
2) "key:__rand_int__"
3) "k1"
4) "myset:__rand_int__"
5) "mylist"
127.0.0.1:6379> select 1
OK
127.0.0.1:6379[1]> flushall
OK
127.0.0.1:6379[1]> select 0
OK
127.0.0.1:6379> keys *
(empty list or set)
```

测试连接:

```
$ k exec -it redis-client -- /bin/bash
I have no name!@redis-client:/$ redis-cli -h redis-redis-ha-haproxy.redis-ha
I have no name!@redis-client:/$ redis-cli -h redis-redis-ha-haproxy.redis-ha info replication | grep role
```


### 参考文章
- https://github.com/DandyDeveloper/charts/tree/master/charts/redis-ha