## **前言**

Redis是一种高级 key-value 型的NoSQL数据库。它跟 memcached类似是内存型数据库，不过Redis数据可以做持久化，即内存中的数据可以同步到磁盘进行存储。而且Redis所支持的数据类型很丰富。有字符串，链表，集合和有序集合等。Redis支持在服务器端计算集合的并交和补集(difference)等，还支持多种排序功能。所以Redis也可以被看成是一个数据结构型服务器。

Redis的所有数据都是保存在内存中，然后不定期的通过异步方式保存到磁盘上(这称为“半持久化模式” RDB)；也可以把每一次数据变化都写入到一个 append only file(AOF)里面(这称为“全持久化模式”)。

Redis的数据都存放在内存中，如果没有配置持久化功能，Redis重启后数据就全丢失了，于是需要开启Redis的持久化功能，将数据保存到磁盘上，当Redis重启后，可以从磁盘中恢复数据。Redis提供两种方式进行持久化，一种是 RDB 持久化（原理是将 Redis在内存中的数据库记录定时 dump 到磁盘上的 RDB 持久化），另外一种是 AOF（append only file）持久化（原理是将Redis的操作日志以追加的方式写入文件）。那么这两种持久化方式有什么区别呢，改如何选择呢？



## **Redis 持久化机制优缺点对比**

**RDB**

优势：

1. 单一文件，适合大规模数据备份和灾难恢复。
2. 性能高，因为 Redis 主进程在持久化时只需做 fork 操作，由子进程完成实际的持久化工作。
3. 对于大数据集，RDB 启动效率更高。

劣势：

1. 无法做到实时或准实时持久化，可能会导致最近一段时间的数据丢失。
2. 若数据集较大，fork 子进程可能会导致服务器短暂停止服务。

**AOF**

优势：

1. 提供更高的数据安全性，可通过配置实现每次修改后同步，减少数据丢失的可能。
2. 即使在写入过程中出现故障，也不会破坏已有的 AOF 文件。
3. 支持日志重写，即在保证数据安全性的前提下，减少磁盘占用。
4. 日志格式清晰，易于理解和人工处理。

劣势：

1. 对于相同的数据集，AOF 文件通常比 RDB 文件大。
2. 数据恢复速度通常比 RDB 慢。
3. 根据同步策略的不同，可能会对性能产生影响。

**选择标准**

- 如果需要最大程度的数据持久性，并且可以接受一些性能开销，那么 AOF 是一个好的选择。
- 如果应用主要是读取操作，数据更新不频繁，或者更关心性能而不是数据持久性，那么 RDB 可能更适合。
- 也可以同时使用 RDB 和 AOF，结合两者的优点。例如，使用 RDB 进行定期备份，用于快速恢复大数据集，同时使用 AOF 提供更高的数据持久性。


## **Redis 持久化配置**

### **RDB持久化配置**

Redis会将数据集的快照dump到dump.rdb文件中。此外，我们也可以通过配置文件来修改Redis服务器dump快照的频率，在打开 6379.conf文件之后，我们搜索save可以看到下面的配置信息：

- save 900 1		#在900秒(15 分钟)之后，如果至少有1个key发生变化，则dump内存快照。
- save 300 10		#在300秒(5 分钟)之后，如果至少有10个key发生变化，则dump内存快照。
- save 60 10000		#在60秒(1 分钟)之后，如果至少有10000个key发生变化，则dump内存快照。


```shell
[root@redis ~]# vim /etc/redis/6379.conf
219 save 900 1
220 save 300 10
221 save 60 10000

242 rdbcompression yes
254 dbfilename dump.rdb
264 dir /var/lib/redis/6379

[root@redis utils]# redis-cli -h 127.0.0.1 -p 6379
127.0.0.1:6379> set name crushlinux
OK
127.0.0.1:6379> set age 18
OK
127.0.0.1:6379> set address beijing
OK
127.0.0.1:6379> 
127.0.0.1:6379> keys *
1) "address"
2) "age"
3) "name"
127.0.0.1:6379> save
OK
127.0.0.1:6379> exit

[root@redis ~]# ls /var/lib/redis/6379
dump.rdb

[root@redis ~]# /etc/init.d/redis_6379 restart
Stopping ...
Redis stopped
Starting Redis server...
[root@redis ~]# redis-cli -h 127.0.0.1 -p 6379
127.0.0.1:6379> keys *
1) "name"
2) "address"
127.0.0.1:6379> get name
"crushlinux"
127.0.0.1:6379> get address
"beijing"

[root@redis ~]# /etc/init.d/redis_6379 stop
Stopping ...
Redis stopped
[root@redis ~]# rm -rf /var/lib/redis/6379/dump.rdb 
[root@redis ~]# /etc/init.d/redis_6379 start
Starting Redis server...
[root@redis ~]# ls /var/lib/redis/6379/
[root@redis ~]# redis-cli -h 127.0.0.1 -p 6379
127.0.0.1:6379> keys *
(empty list or set)

```

### **AOF持久化配置**
Redis的配置文件中存在三种同步方式，它们分别是：

- appendfsync always	#每次有数据修改发生时都会写入AOF文件。
- appendfsync everysec	#每秒钟同步一次，该策略为AOF的缺省策略。
- appendfsync no		#从不同步。高效但是数据不会被持久化。

```
[root@redis ~]# /etc/init.d/redis_6379 stop
[root@redis ~]# rm -rf /var/lib/redis/6379/dump.rdb 
[root@redis ~]# /etc/init.d/redis_6379 start

[root@redis ~]# vim /etc/redis/6379.conf 
673 appendonly yes
703 appendfsync everysec
677 appendfilename "appendonly.aof"
744 auto-aof-rewrite-percentage 100
745 auto-aof-rewrite-min-size 64mb

[root@redis ~]# service redis_6379 restart
[root@redis ~]# redis-cli 
127.0.0.1:6379> set name crushlinux
OK
127.0.0.1:6379> set age 18
OK
127.0.0.1:6379> set address beijing
OK
127.0.0.1:6379> exit
[root@redis ~]# ls /var/lib/redis/6379/
appendonly.aof  dump.rdb
[root@redis ~]# rm -rf /var/lib/redis/6379/dump.rdb
[root@redis ~]# cat /var/lib/redis/6379/appendonly.aof 
*2
$6
SELECT
$1
0
*3
$3
set
$4
name
$10
crushlinux
*3
$3
set
$3
age
$2
18
*3
$3
set
$7
address
$7
beijing
[root@redis ~]# service redis_6379 restart
Stopping ...
Redis stopped
Starting Redis server...
[root@redis ~]# redis-cli 
127.0.0.1:6379> keys *
1) "age"
2) "address"
3) "name"
127.0.0.1:6379> exit
```

### **AOF 重写功能**
AOF持久化存在以下缺点：
- Redis会不断地将被执行的命令记录到AOF文件里面，所以随着Redis不断运行，AOF文件的体积也会不断增长。在极端情况下，体积不断增大的AOF文件甚至可能会用完硬盘的所有可用空间。
- Redis在重启之后需要通过重新执行 AOF 文件记录的所有写命令来还原数据集，所以如果AOF文件的体积非常大，那么还原操作执行的时间就可能会非常长。

为了解决AOF文件体积不断增大的问题，用户可以向Redis发送BGREWRITEAOF命令，这个命令会通过移除AOF文件中的冗余命令来重写（rewrite）AOF文件，使AOF文件的体积变得尽可能地小。BGREWRITEAOF的工作原理和BGSAVE创建快照的工作原理非常相似： Redis会创建一个子进程，然后由子进程负责对AOF文件进行重写。因为AOF文件重写也需要用到子进程，所以快照持久化因为创建子进程而导致的性能问题和内存占用问题，在AOF持久化中也同样存在。

跟快照持久化可以通过设置save选项来自动执行BGSAVE一样，AOF持久化也可以通过设置auto-aof-rewrite-percentage选项和 auto-aof-rewrite-min-size选项来自动执行BGREWRITEAOF。

举个例子，假设用户对Redis设置了配置选项auto-aof-rewrite-percentage 100和 auto-aof-rewrite-min-size 64mb，并且启动了AOF持久化，那么当AOF文件的体积大于64MB，并且AOF文件的体积比上一次重写之后的体积大了至少一倍（100%）的时候，Redis将执行 BGREWRITEAOF 命令。如果AOF重写执行得过于频繁的话，用户可以考虑将 auto-aof-rewrite-percentage 选项的值设置为100以上，这种做法可以让Redis在AOF文件的体积变得更大之后才执行重写操作，不过也会让Redis在启动时还原数据集所需的时间变得更长。


### **参考文章**

- https://github.com/barry-boy/barry-boy.github.io/issues/74