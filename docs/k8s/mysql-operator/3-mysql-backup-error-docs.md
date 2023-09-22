## **前言**

我们本地环境遇到一次ceph集群挂了，导致整个环境的数据丢失，当然mysql数据也丢了。我们的开始希望我们将线上的数据恢复到本地。为此记录一下恢复数据遇到的一些头大的问题。

**恢复步骤: **


- 首先需要下载下来数据库的备份数据，但是我发现如果从ucloud将备份文件下载解压还原后无法启动数据库
- 即使还原成功，`show tables;` 无法查看任何表
- 尝试使用mysqldump 来备份整个库，然后进行还原(但是出现了一个问题)，`Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events.
mysqldump: Error 2020: Got packet bigger than` max_allowed_packet `bytes when dumping table job_metrics at row: 87`

- 在当前 `/etc/mysql/conf.d/` 目录下

```
cat mysqldump.cnf
[mysqldump]
quick
quote-names
max_allowed_packet	= 16G # 本身的单位是M，该成G可以解决这个问题
```

- 还原: `source /backup-path/xxx.sql`











### **文章参考**

- https://www.starcto.com/mysql/315.html