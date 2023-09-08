

## **Docker proxy 代理 pull 国外镜像**

首先需要一台可以翻墙的机器,这边就用我的 Mac.

### **docker proxy 配置**

docker 本身是支持在 docker pull 使用代理的，那么配个代理不久解决问题了吗。

首先 mkdir /etc/systemd/system/docker.service.d。
然后创建 /etc/systemd/system/docker.service.d/http-proxy.conf，添加内容如下：

```shell
[Service]
Environment="HTTP_PROXY=http://localhost:7890/"
Environment="HTTPS_PROXY=https:/locahost:7890/"
#Environment="NO_PROXY=localhost,.docker.io,.docker.com,.daocloud.io"
```

当然要使用自己的 HTTP_PROXY 和 HTTPS_PROXY，然后把不想使用代理的域名添加到 NO_PROXY，尤其是使用的镜像域名和 docker.io 应该考虑在内。

最后更新 systemctl 并重启服务

```shell
$ systemctl daemon-reload
$ systemctl restart docker
```

pull 一个镜像测试一下：

```shell
docker pull k8s.gcr.io/kube-scheduler-amd64:v1.10.2
```


临时测试:

```
http_proxy=http://localhost:7890 https_proxy=http://localhost:7890 curl google.com

export http_proxy=http://localhost:7890
export https_proxy=http://localhost:7890

```


本地端口转发:

```shell
ssh -R 7890:localhost:7890 主机
```



### **镜像加速**

很多镜像都在国外，比如 gcr。国内下载很慢，需要加速。 DaoCloud 为此提供了国内镜像加速，便于从国内拉取这些镜像。


增加前缀（推荐）：

```
k8s.gcr.io/coredns/coredns => m.daocloud.io/k8s.gcr.io/coredns/coredns
```
修改镜像仓库的前缀

```
k8s.gcr.io/coredns/coredns => k8s-gcr.m.daocloud.io/coredns/coredns
```

### **参考文章**

- https://docs.daocloud.io/community/mirror/