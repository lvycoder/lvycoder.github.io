

# **Mac 制作Linux系统盘（其他发行版都可以）**


1.1. Convert ISO file to RAW img file"

   ```shell
   $ hdiutil convert -format UDRW -o target.img ~/Downloads/CentOS-7-x86_64-Minimal-2009.iso
   正在读取Master Boot Record（MBR：0）…
   正在读取CentOS 7 x86_64                 （Apple_ISO：1）…
   正在读取（Type EF：2）…
   .
   正在读取CentOS 7 x86_64                 （Apple_ISO：3）…
   ...............................................................................
   已耗时： 1.235s
   速度：787.3MB/秒
   节省：0.0%
   created: /Users/bougou/target.img.dmg
   ```


1.2. Get USB dev id

```shell
$ diskutil list
/dev/disk0 (internal):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                         1.0 TB     disk0
   1:             Apple_APFS_ISC                         524.3 MB   disk0s1
   2:                 Apple_APFS Container disk3         994.7 GB   disk0s2
   3:        Apple_APFS_Recovery                         5.4 GB     disk0s3

/dev/disk3 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +994.7 GB   disk3
                                 Physical Store disk0s2
   1:                APFS Volume Macintosh HD            15.2 GB    disk3s1
   2:              APFS Snapshot com.apple.os.update-... 15.2 GB    disk3s1s1
   3:                APFS Volume Preboot                 614.7 MB   disk3s2
   4:                APFS Volume Recovery                1.6 GB     disk3s3
   5:                APFS Volume Data                    120.9 GB   disk3s5
   6:                APFS Volume VM                      20.5 KB    disk3s6

/dev/disk4 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *15.5 GB    disk4
   1:                       0xEF                         9.0 MB     disk4s2
```

1.3. unmountDisk

```shell
$ diskutil umountDisk /dev/disk4
Unmount of all volumes on disk4 was successful
```
1.4. dd and eject USB

```shell
$ sudo dd if=~/target.img.dmg of=/dev/disk4 bs=1m
Password:
972+1 records in
972+1 records out
1019942912 bytes transferred in 47.017375 secs (21692894 bytes/sec)
```