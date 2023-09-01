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

![](https://pic.imgdb.cn/item/64f1922c661c6c8e545230d7.jpg)

- NVMe SSD ，这种nvme的盘也是很常见的，这个需要安装linux安装`nvme-tools` 就可以使用`nvme list` 来查看了

- U.2 SSD,这种盘一般需要服务器接口支持才能够使用。一般这种盘比较昂贵。 