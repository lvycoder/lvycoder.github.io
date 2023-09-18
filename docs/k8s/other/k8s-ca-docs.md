利用kubeadm部署的k8s集群，每过一年证书就会过期，为了解决证书过期的问题，可以通过以下方式解决:

- 主要针对的k8s v1.15之前的版本和v1.15之后的版本


## **更新证书**
使用 kubeadm 安装 kubernetes 集群非常方便，但是也有一个比较烦人的问题就是默认的证书有效期只有一年时间，所以需要考虑证书升级的问题，本文的演示集群版本为 v1.16.2 版本，不保证下面的操作对其他版本也适用，在操作之前一定要先对证书目录进行备份，防止操作错误进行回滚。本文主要介绍两种方式来更新集群证书。


## **手动更新证书**
由 kubeadm 生成的客户端证书默认只有一年有效期，我们可以通过 check-expiration 命令来检查证书是否过期：

```
$ kubeadm alpha certs check-expiration
CERTIFICATE                EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
admin.conf                 Nov 07, 2020 11:59 UTC   73d             no
apiserver                  Nov 07, 2020 11:59 UTC   73d             no
apiserver-etcd-client      Nov 07, 2020 11:59 UTC   73d             no
apiserver-kubelet-client   Nov 07, 2020 11:59 UTC   73d             no
controller-manager.conf    Nov 07, 2020 11:59 UTC   73d             no
etcd-healthcheck-client    Nov 07, 2020 11:59 UTC   73d             no
etcd-peer                  Nov 07, 2020 11:59 UTC   73d             no
etcd-server                Nov 07, 2020 11:59 UTC   73d             no
front-proxy-client         Nov 07, 2020 11:59 UTC   73d             no
scheduler.conf             Nov 07, 2020 11:59 UTC   73d             no
```

该命令显示 /etc/kubernetes/pki 文件夹中的客户端证书以及 kubeadm 使用的 KUBECONFIG 文件中嵌入的客户端证书的到期时间/剩余时间。

!!! warning "温馨提示"
    很明显还剩余73天就过期了，kubeadm 不能管理由外部 CA 签名的证书，如果是外部得证书，需要自己手动去管理证书的更新

通常情况下，执行`kubeadm alpha certs renew all` 然后需要将 /etc/kubernetes/manifests/ 挪走，比如重命名为 manifests.1 20 秒以上，等待 static pod 全部都关闭了，然后重命名回来，这个步骤就是强迫所有的 static pod 重启，官网文档就是这么建议操作的 就更新完成了。如果考虑原来证书备份，就需要执行以下操作。

```
$ mkdir /etc/kubernetes.bak
$ cp -r /etc/kubernetes/pki/ /etc/kubernetes.bak
$ cp /etc/kubernetes/*.conf /etc/kubernetes.bak

$ cp -r /var/lib/etcd /var/lib/etcd.bak //备份etcd
```

通过上面的命令证书就一键更新完成了，这个时候查看上面的证书可以看到过期时间已经是一年后的时间了。
```
$ kubeadm alpha certs check-expiration
CERTIFICATE                EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
admin.conf                 Aug 26, 2021 03:47 UTC   364d            no
apiserver                  Aug 26, 2021 03:47 UTC   364d            no
apiserver-etcd-client      Aug 26, 2021 03:47 UTC   364d            no
apiserver-kubelet-client   Aug 26, 2021 03:47 UTC   364d            no
controller-manager.conf    Aug 26, 2021 03:47 UTC   364d            no
etcd-healthcheck-client    Aug 26, 2021 03:47 UTC   364d            no
etcd-peer                  Aug 26, 2021 03:47 UTC   364d            no
etcd-server                Aug 26, 2021 03:47 UTC   364d            no
front-proxy-client         Aug 26, 2021 03:47 UTC   364d            no
scheduler.conf             Aug 26, 2021 03:47 UTC   364d            no
```

以上就是证书更新的方法，如果是v15以上的版本。可以通过执行`kubeadm certs check-expiration`来查看证书是否过期。只不过更新的命令改为了`kubeadm certs renew all`.