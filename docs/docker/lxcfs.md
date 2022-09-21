
https://www.vvave.net/archives/introduction-to-linux-kernel-control-groups-v2.html


修改配置文件：/etc/default/grub

```shell
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash systemd.unified_cgroup_hierarchy=no systemd.legacy_systemd_cgroup_controller=no"
```


```
sudo grub-mkconfig -o /boot/grub/grub.cfg
```