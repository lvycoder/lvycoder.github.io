### **6.6. nvme 模块**

- 查看硬盘健康状态 smartctl

```
smartctl -a /dev/nvme10n1
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.15.0-60-generic] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       WUS4BB076D7P3E3
Serial Number:                      A0608B4C
Firmware Version:                   R1110021
PCI Vendor/Subsystem ID:            0x1b96
IEEE OUI Identifier:                0x0014ee
Total NVM Capacity:                 7,681,501,126,656 [7.68 TB]
Unallocated NVM Capacity:           0
Controller ID:                      0
NVMe Version:                       1.3
Number of Namespaces:               1
Namespace 1 Size/Capacity:          7,681,501,126,656 [7.68 TB]
Namespace 1 Formatted LBA Size:     4096
Namespace 1 IEEE EUI-64:            0014ee 83009c4080
Local Time is:                      Thu Feb 29 18:54:34 2024 CST
Firmware Updates (0x19):            4 Slots, Slot 1 R/O, no Reset required
Optional Admin Commands (0x001f):   Security Format Frmw_DL NS_Mngmt Self_Test
Optional NVM Commands (0x005e):     Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp
Log Page Attributes (0x03):         S/H_per_NS Cmd_Eff_Lg
Warning  Comp. Temp. Threshold:     70 Celsius
Critical Comp. Temp. Threshold:     80 Celsius
Namespace 1 Features (0x02):        NA_Fields
```

- 列出nvme相关的磁盘
  
```
apt install nvme-cli -y 
nvme list 
```

- 安装一定的格式输出nvme的磁盘，并统计nvme磁盘的个数
  
```
nvme list | tail -n +3 | awk '{print $1}' | sed 's/\/dev\///' | sort -V | awk '{print "- name: \""$1"\""}'   # 列举出nvme所有磁盘

nvme list | tail -n +3 | awk '{print $1}' | sed 's/\/dev\///' | sort -V | awk '{print "- name: \""$1"\""}' |wc -l # 统计nvme磁盘
```
