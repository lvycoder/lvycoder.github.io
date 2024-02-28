### **6.6. nvme 模块**

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
