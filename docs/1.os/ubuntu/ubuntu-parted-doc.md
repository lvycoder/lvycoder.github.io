

## **Parted 命令**
- 作用: 规划格式化超过2T以上的分区，也可以用于小分区的规划


```
parted /dev/sdb 
mklabel gpt     # 设置分区类型为gpt
mkpart primary 0% 100%  # 开始分区
```
如图所示：

![20231017145706](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231017145706.png)





## 文章参考

- 文章地址: [parted文章](https://hoxis.github.io/linux%E4%B8%8B%E5%A4%A7%E4%BA%8E2TB%E7%A1%AC%E7%9B%98%E6%A0%BC%E5%BC%8F%E5%8C%96%E5%8F%8A%E6%8C%82%E8%BD%BD.html)