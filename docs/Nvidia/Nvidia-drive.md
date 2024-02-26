## 删除nvidia 相关的软件

```shell
// 过滤出来以rc开头和nvidia的包并卸载
dpkg -l |grep nvidia |grep "^rc" |awk '{print $2}' |grep -E 'nvidia' | xargs dpkg  --purge

dpkg -l |grep nvidia |grep "^ii" |awk '{print $2}' |grep -E '^nvidia' | xargs dpkg --force-all  -r

dpkg -l | grep nvidia  | awk '{print $2}' | xargs apt remove -y

dpkg -l | grep nvidia  | awk '{print $2}' | xargs apt purge -y

```