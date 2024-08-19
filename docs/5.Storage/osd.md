# **osd 性能测试**

!!! info "环境要求"
    - 准备一个k8s集群
    - 准备一个ceph集群

## **机械磁盘测试**

!!! info "背景"
    测试机械磁盘更换固态磁盘后，osd的读写速度




### **方法一：Fio 压力测试**

#### **参数说明：**

```shell
fio -filename=/data/fio.img -direct=1 -iodepth 32 -thread -rw=randwrite -ioengine=libaio -bs=4k -size=200m -numjobs=6 -runtime=60 -group_reporting -name=mytest

filename : 压测的文件（挂在ceph的目录下）
-iodepth : 队列深度
-size : 指定写多大的数据
rw : I/O模式，随机读写，顺序读写等等
bs : I/O block大小
```

#### **示例：**

- 4K随机写-iops

```shell
fio -filename=/data/fio.img -direct=1 -iodepth 32 -thread -rw=randwrite -ioengine=libaio -bs=4k -size=200m -numjobs=6 -runtime=60 -group_reporting -name=mytest

mytest: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.16
Starting 6 threads
mytest: Laying out IO file (1 file / 200MiB)
Jobs: 6 (f=6): [w(6)][100.0%][w=15.0MiB/s][w=4089 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=6): err= 0: pid=96930: Mon Aug  1 14:34:37 2022
  write: IOPS=4104, BW=16.0MiB/s (16.8MB/s)(963MiB/60054msec); 0 zone resets
    slat (nsec): min=1755, max=48814k, avg=10925.38, stdev=316419.53
    clat (msec): min=5, max=191, avg=46.76, stdev=13.55
     lat (msec): min=5, max=191, avg=46.77, stdev=13.54
    clat percentiles (msec):
     |  1.00th=[   25],  5.00th=[   29], 10.00th=[   31], 20.00th=[   33],
     | 30.00th=[   37], 40.00th=[   44], 50.00th=[   49], 60.00th=[   53],
     | 70.00th=[   55], 80.00th=[   58], 90.00th=[   61], 95.00th=[   64],
     | 99.00th=[   85], 99.50th=[   96], 99.90th=[  130], 99.95th=[  142],
     | 99.99th=[  163]
   bw (  KiB/s): min=14912, max=19106, per=100.00%, avg=16419.87, stdev=80.74, samples=720
   iops        : min= 3728, max= 4776, avg=4104.83, stdev=20.18, samples=720
  lat (msec)   : 10=0.04%, 20=0.38%, 50=53.46%, 100=45.67%, 250=0.45%
  cpu          : usr=0.19%, sys=0.71%, ctx=182573, majf=1, minf=11
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=99.9%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,246515,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=16.0MiB/s (16.8MB/s), 16.0MiB/s-16.0MiB/s (16.8MB/s-16.8MB/s), io=963MiB (1010MB), run=60054-60054msec

Disk stats (read/write):
  rbd0: ios=4/245332, merge=0/637, ticks=81/11412705, in_queue=10919116, util=57.39%
```


- 4k随机读-iops

```shell
[ucloud] root@master0:~# fio -filename=/data/fio2.img -direct=1 -iodepth 32 -thread -rw=randread  -ioengine=libaio -bs=4k -size=200m -numjobs=6 -runtime=60 -group_reporting -name=mytest
mytest: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.16
Starting 6 threads
mytest: Laying out IO file (1 file / 200MiB)
Jobs: 6 (f=6): [r(6)][88.9%][r=200MiB/s][r=51.2k IOPS][eta 00m:01s]
mytest: (groupid=0, jobs=6): err= 0: pid=101153: Mon Aug  1 14:40:36 2022
  read: IOPS=36.1k, BW=141MiB/s (148MB/s)(1200MiB/8508msec)
    slat (nsec): min=1151, max=14537k, avg=19572.33, stdev=101622.30
    clat (nsec): min=455, max=79415k, avg=5280191.11, stdev=7133988.93
     lat (usec): min=64, max=79418, avg=5299.94, stdev=7130.13
    clat percentiles (usec):
     |  1.00th=[  363],  5.00th=[  865], 10.00th=[ 1237], 20.00th=[ 1778],
     | 30.00th=[ 2245], 40.00th=[ 2704], 50.00th=[ 3163], 60.00th=[ 3720],
     | 70.00th=[ 4490], 80.00th=[ 5866], 90.00th=[10290], 95.00th=[19268],
     | 99.00th=[40109], 99.50th=[44303], 99.90th=[52167], 99.95th=[56361],
     | 99.99th=[65274]
   bw (  KiB/s): min=45752, max=234048, per=98.88%, avg=142805.42, stdev=12299.59, samples=98
   iops        : min=11438, max=58512, avg=35701.11, stdev=3074.86, samples=98
  lat (nsec)   : 500=0.01%
  lat (usec)   : 20=0.01%, 50=0.01%, 100=0.03%, 250=0.38%, 500=1.39%
  lat (usec)   : 750=2.05%, 1000=2.80%
  lat (msec)   : 2=18.03%, 4=39.21%, 10=25.81%, 20=5.53%, 50=4.61%
  lat (msec)   : 100=0.14%
  cpu          : usr=1.03%, sys=3.66%, ctx=239175, majf=0, minf=198
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=99.9%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=307200,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=141MiB/s (148MB/s), 141MiB/s-141MiB/s (148MB/s-148MB/s), io=1200MiB (1258MB), run=8508-8508msec

Disk stats (read/write):
  rbd0: ios=298435/0, merge=1141/0, ticks=1470086/0, in_queue=887248, util=98.83%
```

- 4k随机读写-iops

```shell
[ucloud] root@master0:~# fio -filename=/data/fio3.img -direct=1 -iodepth 32 -thread -rw=randrw  -rwmixread=70  -ioengine=libaio -bs=4k -size=200m -numjobs=6 -runtime=60 -group_reporting -name=mytest
mytest: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=32
...
fio-3.16
Starting 6 threads
Jobs: 6 (f=6): [m(6)][100.0%][r=26.7MiB/s,w=11.6MiB/s][r=6835,w=2976 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=6): err= 0: pid=104592: Mon Aug  1 14:45:40 2022
  read: IOPS=6434, BW=25.1MiB/s (26.4MB/s)(838MiB/33355msec)
    slat (nsec): min=1268, max=512155, avg=5128.49, stdev=4908.50
    clat (usec): min=108, max=237284, avg=17218.47, stdev=13454.22
     lat (usec): min=112, max=237286, avg=17223.74, stdev=13454.22
    clat percentiles (usec):
     |  1.00th=[   857],  5.00th=[  1696], 10.00th=[  2507], 20.00th=[  4293],
     | 30.00th=[  6980], 40.00th=[ 12256], 50.00th=[ 17695], 60.00th=[ 20579],
     | 70.00th=[ 22938], 80.00th=[ 25560], 90.00th=[ 31589], 95.00th=[ 41157],
     | 99.00th=[ 55313], 99.50th=[ 64226], 99.90th=[ 94897], 99.95th=[154141],
     | 99.99th=[227541]
   bw (  KiB/s): min=18128, max=31360, per=99.94%, avg=25724.41, stdev=445.55, samples=396
   iops        : min= 4532, max= 7840, avg=6430.97, stdev=111.38, samples=396
  write: IOPS=2775, BW=10.8MiB/s (11.4MB/s)(362MiB/33355msec); 0 zone resets
    slat (nsec): min=1519, max=586139, avg=5581.99, stdev=5697.03
    clat (usec): min=735, max=234047, avg=29153.24, stdev=13547.74
     lat (usec): min=740, max=234050, avg=29158.97, stdev=13547.75
    clat percentiles (msec):
     |  1.00th=[    5],  5.00th=[   14], 10.00th=[   19], 20.00th=[   21],
     | 30.00th=[   23], 40.00th=[   24], 50.00th=[   26], 60.00th=[   28],
     | 70.00th=[   33], 80.00th=[   40], 90.00th=[   46], 95.00th=[   52],
     | 99.00th=[   67], 99.50th=[   77], 99.90th=[  153], 99.95th=[  215],
     | 99.99th=[  230]
   bw (  KiB/s): min= 7264, max=13640, per=99.93%, avg=11092.62, stdev=204.64, samples=396
   iops        : min= 1816, max= 3410, avg=2773.11, stdev=51.15, samples=396
  lat (usec)   : 250=0.01%, 500=0.12%, 750=0.35%, 1000=0.56%
  lat (msec)   : 2=3.77%, 4=8.37%, 10=13.38%, 20=18.51%, 50=52.05%
  lat (msec)   : 100=2.75%, 250=0.11%
  cpu          : usr=0.42%, sys=1.37%, ctx=262129, majf=1, minf=6
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=99.9%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.1%, 64=0.0%, >=64=0.0%
     issued rwts: total=214635,92565,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
   READ: bw=25.1MiB/s (26.4MB/s), 25.1MiB/s-25.1MiB/s (26.4MB/s-26.4MB/s), io=838MiB (879MB), run=33355-33355msec
  WRITE: bw=10.8MiB/s (11.4MB/s), 10.8MiB/s-10.8MiB/s (11.4MB/s-11.4MB/s), io=362MiB (379MB), run=33355-33355msec

Disk stats (read/write):
  rbd0: ios=212275/91760, merge=1000/200, ticks=3650146/2659754, in_queue=5701392, util=86.01%
```


- 1M顺序写-吞吐

```shell
[ucloud] root@master0:~# fio -filename=/data/fio4.img -direct=1 -iodepth 32 -thread -rw=write  -ioengine=libaio -bs=1M -size=200m -numjobs=6 -runtime=60 -group_reporting -name=mytest
mytest: (g=0): rw=write, bs=(R) 1024KiB-1024KiB, (W) 1024KiB-1024KiB, (T) 1024KiB-1024KiB, ioengine=libaio, iodepth=32
...
fio-3.16
Starting 6 threads
Jobs: 3 (f=3): [_(2),W(2),_(1),W(1)][90.0%][w=177MiB/s][w=177 IOPS][eta 00m:01s]
mytest: (groupid=0, jobs=6): err= 0: pid=107996: Mon Aug  1 14:51:00 2022
  write: IOPS=131, BW=131MiB/s (138MB/s)(1200MiB/9131msec); 0 zone resets
    slat (usec): min=41, max=13194, avg=208.41, stdev=756.44
    clat (msec): min=20, max=3855, avg=1392.05, stdev=816.66
     lat (msec): min=20, max=3855, avg=1392.26, stdev=816.65
    clat percentiles (msec):
     |  1.00th=[  284],  5.00th=[  351], 10.00th=[  435], 20.00th=[  625],
     | 30.00th=[  885], 40.00th=[ 1099], 50.00th=[ 1234], 60.00th=[ 1418],
     | 70.00th=[ 1620], 80.00th=[ 1938], 90.00th=[ 2769], 95.00th=[ 2903],
     | 99.00th=[ 3608], 99.50th=[ 3675], 99.90th=[ 3809], 99.95th=[ 3842],
     | 99.99th=[ 3842]
   bw (  KiB/s): min=24554, max=273468, per=99.58%, avg=134013.71, stdev=11587.87, samples=93
   iops        : min=   22, max=  267, avg=130.28, stdev=11.35, samples=93
  lat (msec)   : 50=0.25%, 250=0.33%, 500=13.33%, 750=11.50%, 1000=10.08%
  lat (msec)   : 2000=44.92%, >=2000=19.58%
  cpu          : usr=0.18%, sys=0.09%, ctx=792, majf=1, minf=6
  IO depths    : 1=0.5%, 2=1.0%, 4=2.0%, 8=4.0%, 16=8.0%, 32=84.5%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=99.4%, 8=0.0%, 16=0.0%, 32=0.6%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,1200,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=32

Run status group 0 (all jobs):
  WRITE: bw=131MiB/s (138MB/s), 131MiB/s-131MiB/s (138MB/s-138MB/s), io=1200MiB (1258MB), run=9131-9131msec

Disk stats (read/write):
  rbd0: ios=0/887, merge=0/280, ticks=0/1112233, in_queue=1110460, util=16.67%
```



### **方法二：RBD bench 压力测试**

#### **参数说明：**
```yaml
[ucloud] root@master0:~# rbd help bench
usage: rbd bench [--pool <pool>] [--namespace <namespace>] [--image <image>]
                 [--io-size <io-size>] [--io-threads <io-threads>]
                 [--io-total <io-total>] [--io-pattern <io-pattern>]
                 [--rw-mix-read <rw-mix-read>] --io-type <io-type>
                 <image-spec>

Simple benchmark.

Positional arguments
  <image-spec>         image specification
                       (example: [<pool-name>/[<namespace>/]]<image-name>)

Optional arguments
  -p [ --pool ] arg    pool name                        # 指定pool的名称
  --namespace arg      namespace name                   # 指定namespace
  --image arg          image name
  --io-size arg        IO size (in B/K/M/G/T) [default: 4K]                 # 指定IO大小
  --io-threads arg     ios in flight [default: 16]                          # 指定并发
  --io-total arg       total size for IO (in B/K/M/G/T) [default: 1G]       # 数据的大小
  --io-pattern arg     IO pattern (rand, seq, or full-seq) [default: seq]   # iops（rand为随机，seq顺序）
  --rw-mix-read arg    read proportion in readwrite (<= 100) [default: 50]  # --rw-mix-read 混合读写读的占比
  --io-type arg        IO type (read, write, or readwrite(rw))              # 类型，要以什么方式压测，读或者写
```

#### **示例：**

!!! info "温馨提示"
    压测时，可以通过iostat -x 1 对磁盘进行监控
    - ceph osd perf 可以使用该命令查看osd延迟情况
- 4K随机写

```shell
rbd bench rook/rook-rbd.img --io-size 4K --io-threads 16 --io-total 1G --io-pattern rand --io-type write

bench  type write io_size 4096 io_threads 16 bytes 1073741824 pattern random
  SEC       OPS   OPS/SEC   BYTES/SEC
    1      5536   5574.28    22 MiB/s
    2      9664   4849.68    19 MiB/s
    3     13776   4603.46    18 MiB/s
    4     17968   4500.49    18 MiB/s
    ......
   64    261440   3935.99    15 MiB/s
elapsed: 64   ops: 262144   ops/sec: 4064.99   bytes/sec: 16 MiB/s   # 测试出当前的iops为4064.99
```

- 4K随机读

```shell
[ucloud] root@master0:~# rbd bench rook/rook-rbd.img --io-size 4K --io-threads 16 --io-total 1G --io-pattern rand --io-type read
bench  type read io_size 4096 io_threads 16 bytes 1073741824 pattern random
  SEC       OPS   OPS/SEC   BYTES/SEC
    1     26816   26939.7   105 MiB/s
    2     53728   26925.8   105 MiB/s
    3     81648   27257.6   106 MiB/s
    4     90896   22569.9    88 MiB/s
    5    115328   23087.2    90 MiB/s
    6    142416   23119.9    90 MiB/s
    7    170048   23263.9    91 MiB/s
    8    197104   23091.1    90 MiB/s
    9    225264   27046.6   106 MiB/s
   10    253360   27606.3   108 MiB/s
elapsed: 10   ops: 262144   ops/sec: 25391.6   bytes/sec: 99 MiB/s      # 测试出当前的iops为25391.6
```

- 4K随机混合读写

```shell
[ucloud] root@master0:~# rbd bench rook/rook-rbd.img --io-size 4K --io-threads 16 --io-total 1G --io-pattern rand --io-type readwrite --rw-mix-read 70
bench  type readwrite read:write=70:30 io_size 4096 io_threads 16 bytes 1073741824 pattern random
  SEC       OPS   OPS/SEC   BYTES/SEC
    1     12144   12208.8    48 MiB/s
    2     23488   11775.5    46 MiB/s
    3     34624     11562    45 MiB/s
    4     45552   11403.4    45 MiB/s
    5     56528   11317.8    44 MiB/s
    6     67664     11104    43 MiB/s
    7     78976   11097.6    43 MiB/s
    8     89872   11049.6    43 MiB/s
    9    101216   11132.8    43 MiB/s
   10    112608     11216    44 MiB/s
.....
elapsed: 23   ops: 262144   ops/sec: 11012.6   bytes/sec: 43 MiB/s
read_ops: 183730   read_ops/sec: 7718.43   read_bytes/sec: 30 MiB/s
write_ops: 78414   write_ops/sec: 3294.14   write_bytes/sec: 13 MiB/s
```


- 1M顺序写（测吞吐量）

```shell
[ucloud] root@master0:~# rbd bench rook/rook-rbd.img --io-size 1M --io-threads 16 --io-total 200M --io-pattern seq --io-type write
bench  type write io_size 1048576 io_threads 16 bytes 209715200 pattern sequential
  SEC       OPS   OPS/SEC   BYTES/SEC
    1       160   175.298   175 MiB/s
elapsed: 1   ops: 200   ops/sec: 136.986   bytes/sec: 137 MiB/s
```


- https://bench.sh/



