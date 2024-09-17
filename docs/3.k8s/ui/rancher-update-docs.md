这一章的内容主要来讲讲rancher如何升级，我们环境中k8s的版本较高，所以因此需要对rancher版本升级使用gitops。

备份一下旧的values文件
```
$ helm get values rancher > rancher-values.yanl
$ cat rancher-values.yaml
USER-SUPPLIED VALUES:
hostname: rancher.openbayes.com
ingress:
  tls:
    source: letsEncrypt
letsEncrypt:
  email: dev@openbayes.com
```

备份rancher-webhook的values文件
```
$ helm get values rancher-webhook > rancher-webhook-values.yaml
$ cat rancher-webhook-values.yaml
USER-SUPPLIED VALUES:
capi:
  enabled: true
global:
  cattle:
    systemDefaultRegistry: ""
mcm:
  enabled: true
```

Rancher 升级
```
helm upgrade --install rancher rancher-stable/rancher \
--namespace cattle-system -f rancher-values.yaml --version 2.7.5
```


### **参考文章**

- [官方升级文档](https://ranchermanager.docs.rancher.com/zh/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster/upgrades)
- [rancher 版本兼容性文章](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-7-5/)