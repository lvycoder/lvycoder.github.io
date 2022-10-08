# **Juicefs机器学习存储方案**
!!! info "环境要求"
    - docker环境
    - k3s 环境安装
    - redis数据库
    - rook-ceph存储

## **juicefs 环境部署**

参考文章: [Juicefs官网]( https://juicefs.com/docs/zh/community/juicefs_on_k3s) 进行部署

!!! wanring "温馨提示"
    - 如果是生产环境需要考虑redis的高可用，以及原数据的备份。


## **Cephfs和juicefs性能对比**

### **基准测试对比**

- cephfs 基准测试

```shell
root@nginx-run-7877759d45-484kx:/data# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=5
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 5 processes
Jobs: 5 (f=5)
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=816: Mon Aug 15 09:48:26 2022
  read: IOPS=33.5k, BW=131MiB/s (137MB/s)(200MiB/1527msec)
    clat (nsec): min=570, max=248033k, avg=29131.89, stdev=2094821.44
     lat (nsec): min=605, max=248033k, avg=29167.63, stdev=2094821.43
    clat percentiles (nsec):
     |  1.00th=[     644],  5.00th=[     708], 10.00th=[     732],
     | 20.00th=[     748], 30.00th=[     756], 40.00th=[     780],
     | 50.00th=[     796], 60.00th=[     828], 70.00th=[     892],
     | 80.00th=[     940], 90.00th=[    1048], 95.00th=[    1160],
     | 99.00th=[    1416], 99.50th=[    1752], 99.90th=[   23168],
     | 99.95th=[ 2899968], 99.99th=[93847552]
   bw (  KiB/s): min=73728, max=196608, per=21.37%, avg=135168.00, stdev=86889.28, samples=2
   iops        : min=18432, max=49152, avg=33792.00, stdev=21722.32, samples=2
  lat (nsec)   : 750=23.25%, 1000=63.18%
  lat (usec)   : 2=13.14%, 4=0.15%, 10=0.12%, 20=0.04%, 50=0.02%
  lat (usec)   : 100=0.01%, 250=0.01%, 500=0.01%
  lat (msec)   : 2=0.01%, 4=0.02%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%
  cpu          : usr=0.72%, sys=6.55%, ctx=81, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

root@nginx-run-7877759d45-484kx:/data# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=5
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 5 processes
Jobs: 5 (f=5)
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=823: Mon Aug 15 09:48:31 2022
  read: IOPS=41.1k, BW=161MiB/s (168MB/s)(200MiB/1246msec)
    clat (nsec): min=620, max=346202k, avg=23787.02, stdev=1805527.05
     lat (nsec): min=654, max=346202k, avg=23822.73, stdev=1805527.05
    clat percentiles (nsec):
     |  1.00th=[     692],  5.00th=[     740], 10.00th=[     748],
     | 20.00th=[     764], 30.00th=[     780], 40.00th=[     804],
     | 50.00th=[     828], 60.00th=[     876], 70.00th=[     924],
     | 80.00th=[     980], 90.00th=[    1128], 95.00th=[    1192],
     | 99.00th=[    1464], 99.50th=[    1672], 99.90th=[   11712],
     | 99.95th=[ 2899968], 99.99th=[63700992]
   bw (  KiB/s): min=159960, max=224614, per=26.87%, avg=192287.00, stdev=45717.28, samples=2
   iops        : min=39990, max=56153, avg=48071.50, stdev=11428.97, samples=2
  lat (nsec)   : 750=9.15%, 1000=72.77%
  lat (usec)   : 2=17.78%, 4=0.09%, 10=0.10%, 20=0.04%, 50=0.01%
  lat (usec)   : 100=0.01%, 250=0.01%, 500=0.01%
  lat (msec)   : 2=0.01%, 4=0.02%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 500=0.01%
  cpu          : usr=0.88%, sys=8.19%, ctx=88, majf=0, minf=15
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=824: Mon Aug 15 09:48:31 2022
```

- jufice 基准测试

```
root@nginx-run-7877759d45-484kx:/config# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=5
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 5 processes
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
big-file-multi-read: Laying out IO file (1 file / 200MiB)
Jobs: 5 (f=5): [R(5)][66.7%][r=304MiB/s][r=77.8k IOPS][eta 00m:02s]
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=831: Mon Aug 15 09:50:58 2022
  read: IOPS=14.9k, BW=58.0MiB/s (60.9MB/s)(200MiB/3446msec)
    clat (nsec): min=373, max=533198k, avg=67006.12, stdev=4299023.59
     lat (nsec): min=406, max=533198k, avg=67043.41, stdev=4299023.63
    clat percentiles (nsec):
     |  1.00th=[      390],  5.00th=[      418], 10.00th=[      462],
     | 20.00th=[      532], 30.00th=[      548], 40.00th=[      564],
     | 50.00th=[      572], 60.00th=[      580], 70.00th=[      596],
     | 80.00th=[      620], 90.00th=[      692], 95.00th=[      860],
     | 99.00th=[    58624], 99.50th=[    86528], 99.90th=[   220160],
     | 99.95th=[  3031040], 99.99th=[248512512]
   bw (  KiB/s): min=24576, max=90112, per=22.61%, avg=64140.67, stdev=22219.00, samples=6
   iops        : min= 6144, max=22528, avg=16035.17, stdev=5554.75, samples=6
  lat (nsec)   : 500=14.08%, 750=78.30%, 1000=4.37%
  lat (usec)   : 2=0.36%, 4=0.65%, 10=0.30%, 20=0.09%, 50=0.28%
  lat (usec)   : 100=1.21%, 250=0.26%, 500=0.03%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=0.01%, 20=0.01%, 50=0.01%, 100=0.01%
  lat (msec)   : 250=0.01%, 500=0.01%, 750=0.01%
  cpu          : usr=0.70%, sys=1.92%, ctx=874, majf=0, minf=16
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

root@nginx-run-7877759d45-484kx:/config# fio --name=big-file-multi-read --directory=$PWD --rw=read --refill_buffers --bs=4K --size=200M --numjobs=5
big-file-multi-read: (g=0): rw=read, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
...
fio-3.25
Starting 5 processes

big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=838: Mon Aug 15 09:51:22 2022
  read: IOPS=157k, BW=613MiB/s (643MB/s)(200MiB/326msec)
    clat (nsec): min=379, max=7481.0k, avg=5697.24, stdev=75385.63
     lat (nsec): min=411, max=7481.1k, avg=5733.65, stdev=75387.68
    clat percentiles (nsec):
     |  1.00th=[    458],  5.00th=[    498], 10.00th=[    524],
     | 20.00th=[    556], 30.00th=[    572], 40.00th=[    580],
     | 50.00th=[    596], 60.00th=[    612], 70.00th=[    636],
     | 80.00th=[    684], 90.00th=[    852], 95.00th=[    964],
     | 99.00th=[ 102912], 99.50th=[ 280576], 99.90th=[ 962560],
     | 99.95th=[1302528], 99.99th=[2539520]
  lat (nsec)   : 500=5.63%, 750=79.66%, 1000=10.50%
  lat (usec)   : 2=1.80%, 4=0.02%, 10=0.21%, 20=0.06%, 50=0.26%
  lat (usec)   : 100=0.84%, 250=0.45%, 500=0.38%, 750=0.07%, 1000=0.03%
  lat (msec)   : 2=0.08%, 4=0.01%, 10=0.01%
  cpu          : usr=5.85%, sys=27.08%, ctx=1348, majf=0, minf=17
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=51200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
big-file-multi-read: (groupid=0, jobs=1): err= 0: pid=839: Mon Aug 15 09:51:22 2022
```