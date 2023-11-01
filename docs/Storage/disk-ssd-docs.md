## **存储的分类:**


### **存储分类**

**单机存储:**

- SCSI/IDE/SATA//SAS/USB/PCI-E/SSD/M.2 NVME 协议(提升性能)

SATA/IDE:

![20231101170635](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231101170635.png)

SATA ssd:

- https://item.jd.com/49620677951.html#crumb-wrap

![20231101171155](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231101171155.png)

nvme ssd:

https://item.jd.com/10070004737561.html

![20231101172449](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231101172449.png)

M.2 :

![20231101172815](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231101172815.png)


**网络存储:**

- NFS
- Samba

![20231101174931](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231101174931.png)
### **固态存储**

这次迁移机房,让我了解到真多硬盘的相关知识,之前一直使用的普通机械盘,一直对固态 ssd 欠缺了解,这次也大概了解到了几种.

常见固态类型: 

- SATA SSD：这种 SSD 使用 SATA（Serial ATA）接口连接到计算机上。虽然 SATA SSD 的速度比 NVMe SSD 慢，但它们通常更便宜，且兼容性更好。
- NVMe SSD：NVMe（Non-Volatile Memory Express）是一种专为 SSD 设计的接口协议，能充分利用 SSD 的高速性能。NVMe SSD 通常连接到主板的 PCIe 插槽上，其数据传输速度远超 SATA 接口的 SSD
- M.2 SSD：M.2 是一种形状和尺寸的规格，可以支持 SATA 或 NVMe 接口。M.2 SSD 可以非常小巧，适合在笔记本电脑和小型计算机中使用。
- U.2 SSD：U.2 SSD 是一种企业级 SSD，主要用于数据中心。U.2 接口支持 NVMe 协议，可以提供高速的数据传输。

以上的四种这次都用到了,

- SATA 盘这种磁盘是我们平时最常用的一种，几乎台式机都是支持SATA接口的。
- https://github.com/barry-boy/note-k8s/issues/58

- M.2 他的样子很像内存条,一般情况用在笔记本中,或者服务器的内部,如图所示:

- NVMe SSD ，这种nvme的盘也是很常见的，这个需要安装linux安装`nvme-tools` 就可以使用`nvme list` 来查看了

- U.2 SSD,这种盘一般需要服务器接口支持才能够使用。一般这种盘比较昂贵。 


### **磁盘管理**

- 查看硬盘的详细信息

```shell
[wlcb] root@stor1:/home/openbayes# smartctl -a /dev/nvme9n1
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.15.0-79-generic] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       WUS4BB076D7P3E3 # 这是硬盘的型号
Serial Number:                      A06460A4 # 这是硬盘的序列号
Firmware Version:                   R1110012 # 这是硬盘的固件版本
PCI Vendor/Subsystem ID:            0x1b96
IEEE OUI Identifier:                0x0014ee
Total NVM Capacity:                 7,681,501,126,656 [7.68 TB] # 这是硬盘的总容量
Unallocated NVM Capacity:           0
Controller ID:                      0
NVMe Version:                       1.3
Number of Namespaces:               1
Namespace 1 Size/Capacity:          7,681,501,126,656 [7.68 TB]
Namespace 1 Formatted LBA Size:     4096 # 这是命名空间 1 的格式化 LBA 大小
Namespace 1 IEEE EUI-64:            0014ee 8300ecf800
Local Time is:                      Wed Nov  1 17:21:54 2023 CST
Firmware Updates (0x19):            4 Slots, Slot 1 R/O, no Reset required
Optional Admin Commands (0x001f):   Security Format Frmw_DL NS_Mngmt Self_Test
Optional NVM Commands (0x005e):     Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp
Log Page Attributes (0x03):         S/H_per_NS Cmd_Eff_Lg
Warning  Comp. Temp. Threshold:     70 Celsius # 这是硬盘的警告温度阈值
Critical Comp. Temp. Threshold:     80 Celsius # 这是硬盘的临界温度阈值
Namespace 1 Features (0x02):        NA_Fields

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +    12.00W       -        -    0  0  0  0       50      50
 1 +    11.00W       -        -    1  1  1  1       50      50
 2 +    10.00W       -        -    2  2  2  2       50      50
 3 +     9.00W       -        -    3  3  3  3       50      50
 4 +     8.00W       -        -    4  4  4  4       50      50

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +    4096       0         0
 1 -     512       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED # 这是硬盘的自我评估健康检查结果

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        41 Celsius # 这是硬盘的当前温度
Available Spare:                    100% # 这是硬盘的可用备用容量的百分比
Available Spare Threshold:          10%
Percentage Used:                    0% # 这是硬盘已使用的百分比
Data Units Read:                    15,426,092 [7.89 TB] # 这是已读取的数据单元数量
Data Units Written:                 27,113,736 [13.8 TB] # 这是已写入的数据单元数量
Host Read Commands:                 104,197,470
Host Write Commands:                1,044,097,133
Controller Busy Time:               7,011
Power Cycles:                       17
Power On Hours:                     1,037 # 这是硬盘的运行时间
Unsafe Shutdowns:                   11 # 这是不安全关闭的次数
Media and Data Integrity Errors:    0
Error Information Log Entries:      110 # 这是错误信息日志条目的数量
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               39 Celsius # 这是温度传感器1的读数

Error Information (NVMe Log 0x01, 16 of 256 entries)
Num   ErrCount  SQId   CmdId  Status  PELoc          LBA  NSID    VS
  0        110     0  0xf01b  0xc004  0x028            0     0     -
  1        109     0  0x2014  0xc004  0x029            0     0     -
```