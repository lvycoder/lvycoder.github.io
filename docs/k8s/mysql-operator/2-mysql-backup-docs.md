## **MySQL完全备份与恢复**

随着自动化办公与电子商务的不断扩展，企业对于信息系统的依赖性越来越重要，而数据库在信息系统中担任着非常重要的角色。尤其一些对数据库可靠性要求非常高的行业，例如银行，证券，电信等，如果发生意外宕机或数据丢失，其损失是非常重要的。为此数据库管理员必须针对具体的业务要求定制详细的数据库备份与灾难恢复的策略，并通过模拟故障对每种可能的情况进行严格的测试。而保障数据的可靠性。

## **一、数据备份的重要性**

备份的主要目的是灾难恢复，备份还可以测试应用，回滚数据修改，查询历史数据，审计等。我们将从生产运维的角度了解备份恢复的分类与方法。

在企业中数据的价值至关重要，数据保障了企业业务的运行，因此数据的安全性及可靠性是运维的重中之重，任何数据的丢失都有可能会对企业产生严重的后果。造成数据丢失的原因如下：

- 程序错误
- 人为错误
- 数据泄露
- 运算失败
- 磁盘故障
- 灾难（如火灾、地震）



## **二、数据库备份的类型**

### **2.1 从物理与逻辑的角度**

备份可以分为物理备份和逻辑备份。

**物理备份**：对数据库操作系统的物理文件（如数据文件、日志文件等）的备份。物理备份又可分为脱机备份（冷备份）和联机备份（热备份）。这种类型的备份适用于出现问题时需要快速恢复的大型重要数据库。

1. 冷备份：是在关闭数据库的时候进行的
2. 热备份：数据库处于运行状态，这种备份方法依赖于数据库的日志文件
3. 温备份：数据库锁定表格（不可写入但可读）的状态下进行的

**逻辑备份**：对数据库逻辑组件（如表等数据库对象）的备份，表示为逻辑数据库结构（create database、create table等语句）和内容（insert语句或分割文本文件）的信息。这种类型的备份适用于可以编辑数据值或表结构较小的数据量，或者在不同机器体系结构上重新创建数据。


### **2.2 从数据库的备份策略角度**

备份可分为完全备份、差异备份和增量备份

1. **完全备份**：每次对数据进行完整的备份，即对整个数据库的备份、数据库结构和文件结构的备份，保存的是备份完成时刻的数据库状态，是差异备份与增量备份的基础。
    - 优点：备份与恢复操作简单方便
    - 缺点：数据存在大量的重复；占用大量的空间；备份与恢复时间长

2. **差异备份**：备份那些自从上次完全备份之后被修改过的所有文件，备份的时间起点是从上次完整备份起，备份数据量会越来越大。恢复数据时，只需恢复上次的完全备份与最近的一次差异备份。

3. **增量备份**：只有那些在上次完全备份或者增量备份后被修改的文件才会被备份。以上次完整备份或上次的增量备份的时间为时间点，仅备份这之间的数据变化，因而备份的数据量小，占用空间小，备份速度快。但恢复时，需要从上一次的完整备份起到最后一次增量备份依次恢复，如中间某次的备份数据损坏，将导致数据的丢失。



### **2.3 常见的备份方法**

MySQL数据库的备份可以采用很多种方式，如直接打包数据库文件（物理冷备份），专用备份工具（mysqldump），二进制日志增量备份，第三方工具备份等。

1. **物理备份**：物理冷备份时需要在数据库处于关闭状态下，能够较好的保证数据库的完整性。物理冷备份以用于非核心业务，这类业务都允许中断，物理冷备份的特点就是速度快，恢复时也是最为简单的，通过直接打包数据库文件夹（/usr/local/mysql/data）来实现备份。

2. **专用备份工具mysqldump或mysqlhotcopy**：mysqldump和mysqlhotcopy都可以做备份。mysqldump是客户端常用逻辑备份程序，能够产生一组被执行以再现原始数据库对象定义和表数据的SQL语句。它可以转储一个到多个MySQL数据库，其进行备份或传输到远程SQL服务器。mysqldump更为通用，因为它可以备份各种表。mysqlhotcopy仅适用于某些存储引擎。mysqlhotcopy是由Tim Bunce最初编写和贡献的Perl脚本。mysqlhotcopy仅用于备份MyISAM和ARCHIVE数据表。只能运行在Unix或Linux操作系统上。

3. **通过启用二进制（binary log，binlog）日志进行增量备份**：MySQL支持增量备份，进行增量备份时必须启用二进制日志。二进制日志文件为用户提供复制。对执行备份点后进行的数据库更改所需的信息进行备份。如果进行增量备份（包含上次完全备份或增量备份以来发生的数据修改），需要刷新二进制日志。

4. **通过第三方工具备份**：Percona XtraBackup是一个免费的MySQL热备份软件，支持在线备份Innodb和XtraDB，也可以支持MySQL表备份，不过MyISAM表的备份要在表锁的情况进行。

    Percona XtraBackup主要的工具：xtrabackup、innobackupex、xbstream

    - xtrabackup：是一个编译了的二进制文件，只能备份Innodb/Xtradb数据文件
   
    - innobackupex：是一个封装了xtrabackup的Perl脚本，除了可以备份Innodb/Xtradb之外，还可以备份MyISAM。
  
    - xbstream：是一个新组件，能够允许将文件格式转换成xbstream格式或从xbstream格式转到文件格式。

    xtrabackup工具可以单独使用，但推荐使用innobackupx来进行备份，因为其本身已经包含了xtrabackup的所有功能。



### **2.4 XtraBackup的备份与恢复**

**XtraBackup** 是基于Innodb的灾难恢复功能进行设计的。备份工具复制Innodb的数据文件，由于不锁表，这样复制出来的数据将不一致。但是，Innodb维护了一个重要的重做日志，包含Innodb数据的所有改动情况。在XtraBackup备份Innodb的数据同时，XtraBackup还有另外一个线程用来监控重做日志，一旦日志发生变化，就把发生变化的日志数据复制走。这样就可以利用重做日志做灾难恢复。

以上是备份过程。如果我们需要恢复数据，则在准备阶段，XtraBackup就需要使用之前复制的重做日志对备份出来的Innodb数据文件进行灾难恢复。此阶段完成之后，数据库就可以进行重建还原了。Percona XtraBackup对MyISAM的复制是按顺序进行的，先锁定表，然后复制，再解锁表。

!!! warning "温馨提示"
    数据库备份策略思考？

    - 1.公司数据库的总数据量多大？ 25~30G 2.每天增长量多大？50M 3.备份的策略？ 4.备份数据量？ 5.备份的时长？



## **三、MySQL完全备份操作**

MySQL数据库的完全备份可以采用多种方式，物理冷备份一般用tar命令直接打包数据库文件夹（数据目录），而在备份前需要先停库。

### **1、直接打包数据库文件夹**
- 源码包的位置/usr/local/mysql/data/，rpm包的位置 /var/lib/mysql/


```
[root@localhost ~]# /etc/init.d/mysqld start
Starting MySQL............... SUCCESS! 
[root@localhost ~]# netstat -lnpt | grep :3306
tcp6       0      0 :::3306                 :::*                    LISTEN      1630/mysqld         
[root@localhost ~]# mysql -u root -p123456
mysql> create database auth;
Query OK, 1 row affected (0.00 sec)

mysql> use auth;
Database changed
mysql> create table user(name char(10) not null,ID int(48));
Query OK, 0 rows affected (0.04 sec)

mysql> insert into user values('crushlinux','123');
Query OK, 1 row affected (0.01 sec)

mysql> select * from user;
+------------+------+
| name       | ID   |
+------------+------+
| crushlinux |  123 |
+------------+------+
1 row in set (0.00 sec) 

mysql> exit
Bye
```

停止数据库，进行备份。

```
[root@localhost ~]# /etc/init.d/mysqld stop
Shutting down MySQL.. SUCCESS!

[root@localhost ~]# mkdir backup
[root@localhost ~]# tar zcf backup/mysql_all-$(date +%F).tar.gz /usr/local/mysql/data/
tar: Removing leading `/' from member names 
[root@localhost ~]# ls -l backup/
总用量 728
-rw-r--r-- 1 root root 742476 12月 14 23:31 mysql_all-2018-12-14.tar.gz
```

模拟丢失:

```
[root@localhost ~]# /etc/init.d/mysqld start
Starting MySQL.. SUCCESS! 
[root@localhost ~]# mysql -uroot -p123456
mysql> drop database auth;
Query OK, 1 row affected (0.02 sec)
```

恢复数据:

```
[root@localhost ~]# /etc/init.d/mysqld stop
Shutting down MySQL.. SUCCESS! 
[root@localhost ~]# mkdir restore
[root@localhost ~]# tar xf backup/mysql_all-2020-04-23.tar.gz -C restore/
[root@localhost ~]# rm -rf /usr/local/mysql/data/*
[root@localhost ~]# mv restore/usr/local/mysql/data/* /usr/local/mysql/data/
[root@localhost ~]# /etc/init.d/mysqld start
Starting MySQL. SUCCESS!
[root@localhost ~]# mysql -uroot -p123456 -e 'select * from auth.user;'
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+------+
| name       | ID   |
+------------+------+
| crushlinux |  123 |
+------------+------+
```

### **2、使用专用备份工具mysqldump**


MySQL自带的备份工具mysqldump，可以很方便的对MySQL进行备份。通过该命令工具可以将数据库、数据表或全部的库导出为SQL脚本，便于该命令在不同版本的MySQL服务器上使用。例如，当需要升级MySQL服务器时，可以先使用mysqldump命令将原有库信息到导出，然后直接在升级后的MySQL服务器中导入即可。


#### 1. 对单个库进行完全备份

**格式：**
```
mysqldump -u用户名 -p[密码] [选项] --databases [数据库名] > /备份路径/备份文件名
```
**示例：**
```
[root@localhost ~]# mysqldump -uroot -p123456 --databases auth > backup/auth-$(date +%Y%m%d).sql
mysqldump: [Warning] Using a password on the command line interface can be insecure.
[root@localhost ~]# cat backup/auth-20181214.sql
```

#### **2. 对多个库进行完全备份**

**格式：**
```
mysqldump -u用户名 -p [密码] [选项] --databases 库名1 [库名2]… > /备份路径/备份文件名
```
**示例：**
```
[root@localhost ~]# mysqldump -uroot -p123456 --databases mysql auth > backup/mysql+auth-$(date +%Y%m%d).sql 
[root@localhost ~]# cat backup/mysql+auth-20181214.sql
```

#### **3. 对所有库进行完全备份**

**格式：**
```
mysqldump -u用户名 -p [密码] [选项] --opt --all-databases > /备份路径/备份文件名
```
**示例：**
```
[root@localhost ~]# mysqldump -uroot -p123456 --opt --all-databases > backup/mysql_all.$(date +%Y%m%d).sql
[root@localhost ~]# cat backup/mysql_all.20181214.sql
//--opt 加快备份速度，当备份数据量大时使用
[root@localhost ~]# cat backup/mysql_all.20160505.sql
```

#### **4. 对表进行完全备份**

**格式：**
```
mysqldump -u用户名 -p [密码] [选项] 数据库名 表名 > /备份路径/备份文件名
```
**示例：**
```
[root@localhost ~]# mysqldump -uroot -p123456 auth user > backup/auth_user-$(date +%Y%m%d).sql
[root@localhost ~]# cat backup/auth_user-20181214.sql
```

#### **5. 对表结构的备份**

**格式：**
```
mysqldump -u用户名 -p [密码] -d 数据库名 表名 > /备份路径/备份文件名
```
**示例：**
```
[root@localhost ~]# mysqldump -uroot -p123456 -d mysql user > backup/desc_mysql_user-$(date +%Y%m%d).sql
[root@localhost ~]# cat backup/desc_mysql_user-20181214.sql
```

## **四、使用mysqldump备份后，恢复数据库**
### **1. 使用source命令**

- 登录到MySQL数据库，执行source 备份sql脚本路径


**示例：**
```
[root@localhost ~]# mysql -uroot -p123456
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| auth               |
| mysql              |
| performance_schema |
| test               |
| usr                |
+--------------------+
6 rows in set (0.00 sec)

mysql> drop database auth;
Query OK, 1 row affected (0.12 sec)

mysql> source backup/auth.20181214.sql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| auth               |
| mysql              |
| performance_schema |
| test               |
| usr                |
+--------------------+
6 rows in set (0.00 sec)
```

### **2. 使用mysql命令**

**格式：**
```
mysql -u用户名 -p [密码] < 库备份脚本的路径
mysql -u用户名 -p [密码] 库名 < 表备份脚本的路径
```

**示例：**
```
[root@localhost ~]# mysql -uroot -p123456 -e 'show databases;'
+--------------------+
| Database           |
+--------------------+
| information_schema |
| auth               |
| mysql              |
| performance_schema |
| test               |
| usr                |
+--------------------+
[root@localhost ~]# mysql -uroot -p123456 -e 'drop database auth;'
[root@localhost ~]# mysql -uroot -p123456 < backup/auth.20181214.sql
[root@localhost ~]# mysql -uroot -p123456 -e 'show databases;'
+--------------------+
| Database           |
+--------------------+
| information_schema |
| auth               |
| mysql              |
| performance_schema |
| test               |
| usr                |
+--------------------+
[root@localhost ~]# mysql -uroot -p123456 -e 'drop table auth.user;'
[root@localhost ~]# mysql -uroot -p123456 auth < backup/auth_user-20181214.sql 
[root@localhost ~]# mysql -uroot -p123456 -e 'select * from auth.user;'
+------------+------+
| name       | ID   |
+------------+------+
| crushlinux |  123 |
+------------+------+
```



## **五、MySQL备份思路**

1、定期实施备份，制定备份计划或策略，并严格遵守。

2、除了进行完全备份，开启MySQL服务器的binlog日志功能是很重要的（完全备份加上日志，可以对MySQL进行最大化还原）。

3、使用统一和易理解的备份名称，推荐使用库名或者表名加上时间的命名规则，如mysql_user-20181214.sql，不要使用backup1或者abc之类没有意义的名字。



## **六、MySQL完全备份案例**

**需求描述：**

用户信息数据库为client，用户资费数据表为user_info，表结构如下所示。请为该公司制定合理的备份策略，依据所制定的策略备份数据，模拟数据丢失进行数据恢复。

![20230922161808](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog20230922161808.png)


创建数据及表，录入数据：

```
[root@localhost ~]# mysql -uroot -p123456
mysql> show variables like 'character_set_%';	//查看字符集是否支持中文
+--------------------------+----------------------------------+
| Variable_name            | Value                            |
+--------------------------+----------------------------------+
| character_set_client     | utf8                             |
| character_set_connection | utf8                             |
| character_set_database   | latin1                           |
| character_set_filesystem | binary                           |
| character_set_results    | utf8                             |
| character_set_server     | latin1                           |
| character_set_system     | utf8                             |
| character_sets_dir       | /usr/local/mysql/share/charsets/ |
+--------------------------+----------------------------------+
8 rows in set (0.01 sec)

[root@localhost ~]# vim /etc/my.cnf
[mysqld]
character_set_server=utf8
[root@localhost ~]# /etc/init.d/mysqld restart

mysql> show variables like 'character_set_%';
+--------------------------+----------------------------------+
| Variable_name            | Value                            |
+--------------------------+----------------------------------+
| character_set_client     | utf8                             |
| character_set_connection | utf8                             |
| character_set_database   | utf8                             |
| character_set_filesystem | binary                           |
| character_set_results    | utf8                             |
| character_set_server     | utf8                             |
| character_set_system     | utf8                             |
| character_sets_dir       | /usr/local/mysql/share/charsets/ |
+--------------------------+----------------------------------+
8 rows in set (0.01 sec)

mysql> create database client;
Query OK, 1 row affected (0.00 sec)

mysql> use client;
Database changed

create table user_info(身份证 int(20),姓名 char(20),性别 char(2),用户ID号 int(110),资费 int(10)) DEFAULT CHARSET=utf8;
insert into user_info values('000000001','孙空武','男','011','100');
insert into user_info values('000000002','蓝凌','女','012','98');
insert into user_info values('000000003','姜纹','女','013','12');
insert into user_info values('000000004','关园','男','014','38');
insert into user_info values('000000004','罗中昆','男','015','39');

mysql> select * from user_info;
+-----------+-----------+--------+-------------+--------+
| 身份证    | 姓名      | 性别   | 用户ID号    | 资费   |
+-----------+-----------+--------+-------------+--------+
|         1 | 孙空武    | 男     |          11 |    100 |
|         2 | 蓝凌      | 女     |          12 |     98 |
|         3 | 姜纹      | 女     |          13 |     12 |
|         4 | 关园      | 男     |          14 |     38 |
|         4 | 罗中昆    | 男     |          15 |     39 |
+-----------+-----------+--------+-------------+--------+
5 rows in set (0.00 sec)
```


完整备份client.user_info表：

```
[root@localhost ~]# mysqldump -uroot -p123456 client user_info > backup/client.user_info-$(date +%Y%m%d).sql
```

模拟数据丢失恢复数据：

```
[root@localhost ~]# mysql -uroot -p123456 -e 'drop table client.user_info;'
[root@localhost ~]# mysql -uroot -p123456 -e 'use client; show tables;'
[root@localhost ~]# mysql -uroot -p123456 client < backup/client.user_info-20181214.sql
[root@localhost ~]# mysql -uroot -p123456 -e 'select * from client.user_info;'
+-----------+-----------+--------+-------------+--------+
| 身份证    | 姓名      | 性别   | 用户ID号    | 资费   |
+-----------+-----------+--------+-------------+--------+
|         1 | 孙空武    | 男     |          11 |    100 |
|         2 | 蓝凌      | 女     |          12 |     98 |
|         3 | 姜纹      | 女     |          13 |     12 |
|         4 | 关园      | 男     |          14 |     38 |
|         4 | 罗中昆    | 男     |          15 |     39 |
+-----------+-----------+--------+-------------+--------+
```


定期备份数据：

```
[root@localhost ~]# which mysqldump
/usr/local/mysql/bin/mysqldump

[root@localhost ~]# vim /opt/bak_client.sh
#!/bin/bash
# 备份client.user_info表 脚本
/usr/local/mysql/bin/mysqldump -uroot -p123456 client user_info >backup/client.user_info-$(date +%Y%m%d).sql

[root@localhost ~]# chmod +x /opt/bak_client.sh 
[root@localhost ~]# crontab -e
0       0       *       *       *       /opt/bak_client.sh		//每天0:00备份
```






























### **参考文章**

- https://satya-dba.blogspot.com/2021/09/percona-xtrabackup-installation.html
- [xtrabackup 解压ucloud数据库文章](https://www.starcto.com/mysql/315.html)