# cka 认证考试

## 1. 监控 pod日志 5%
图示:
![](https://pic.imgdb.cn/item/6386c82216f2c2beb1c78650.jpg)

中文解释:

监控名为 foobar 的 Pod 的日志，并过滤出具有 unable-access-website 信息的行，然后将写入到 /opt/KUTR00101/foobar

解题步骤:
```shell
$ kubectl config use-context k8s
$ kubectl logs foobar | grep unable-access-website > /opt/KUTR00101/foobar
```


## 2.监控 pod 度量 指标: 5%

图示:
![](https://pic.imgdb.cn/item/6386d12f16f2c2beb1d8affb.jpg)

中文解释:

找出具有 name=cpu-user 的 Pod，并过滤出使用 CPU 最高的 Pod，然后把它的名字写在已经存在的/opt/KUTR00401/KUTR00401.txt 文件里  <font color='red'> （注意他没有说指定 namespace。所以需要使用-A 指定所以 namespace） 注意是**追加** </font>

解题步骤:

```shell
$ kubectl config use-context k8s
$ kubectl top pod -A -l |grep name=cpu-user

# 注意这里的 pod 名字以实际名字为准，按照 CPU 那一列进行选择一个最大的 Pod，另外如果
CPU 的数值是 1 2 3 这样的。是大于带 m 这样的，因为 1 颗 CPU 等于 1000m，注意要用>>而不是> 
$ echo "coredns-54d67798b7-hl8xc" >> /opt/KUTR00401/KUTR00401.txt

```

## 3.Deployment 扩缩容

图示:
![](https://pic.imgdb.cn/item/6386d3e816f2c2beb1dcea41.jpg)

中文解释:

扩容名字为 loadbalancer 的 deployment 的副本数为 6

解题步骤:

```shell
$ kubectl config use-context k8s
$ kubectl scale --replicas=6 deployment loadbalancer
$ kubectl edit
```


## 4. 检查 Node 节点的健康状态 

图示:
![](https://pic.imgdb.cn/item/6386d5f716f2c2beb1e0f339.jpg)


中文解释:

检查集群中有多少节点为 Ready 状态，并且去除包含 NoSchedule 污点的节点。之后将数字写到/opt/KUSC00402/kusc00402.txt


解题步骤:

```shell
$ kubectl config use-context k8s
$ kubectl get node | grep -i ready # 记录总数为 A 
$ kubectl describe node | grep Taint | grep NoSchedule 
# 记录总数为 B # 将 A 减 B 的值 x 导入到/opt/KUSC00402/kusc00402.txt
$ echo x >> /opt/KUSC00402/kusc00402.txt
```

## 5. 节点维护 

图示:
![](https://pic.imgdb.cn/item/6386ed5f16f2c2beb105f9fa.jpg)

中文解释:

将 ek8s-node-1 节点设置为不可用，然后重新调度该节点上的所有 Pod

解题步骤:

```shell
$ kubectl config use-context ek8s
$ kubectl cordon ek8s-node-1 
$ kubectl drain ek8s-node-1 --delete-emptydir-data --ignore-daemonsets --force
$ k delete pod  pod-name  --grace-period=0 --force
```

## 6. 指定节点部署

图示:

![](https://pic.imgdb.cn/item/6386effc16f2c2beb10a6a38.jpg)

中文解释:

创建一个 Pod，名字为 nginx-kusc00401，镜像地址是 nginx，调度到具有 disk=spinning 标签的节点上 ， 

- 该题可以参考链接： https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/assign-pods-nodes/

- 该题可以参考链接： https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/


解题步骤:

题目一：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-kusc00401
  labels:
    role: nginx-kusc00401
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    disk: spinning
```

题目二：

```yaml
$ cat 6-2-cka.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-kusc00402
  labels:
    role: nginx-kusc00402
spec:
  nodeName: node1
  containers:
  - name: nginx
    image: nginx
```


## 7. 一个 Pod 多个容器 

图示：
![](https://pic.imgdb.cn/item/6387767c16f2c2beb1f445e8.jpg)

中文解释:

创建一个 Pod ， 名字为 kucc1 ，这个 Pod 可能包含 1-4 容 器 ， 该题为四个 ：nginx+redis+memcached+consul


解题步骤:

```yaml
$ cat 7-cka.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kucc1
spec:
  containers:
  - name: nginx
    image: nginx
  - name: redis
    image: redis
  - name: memcached
    image: memcached
  - name: consul
    image: consul
```

## 8. Service 考题

![](https://pic.imgdb.cn/item/638778cc16f2c2beb1f7d310.jpg)

中文解释:

重新配置一个已经存在的 deployment front-end，在名字为 nginx 的容器里面添加一个端口配置，名字为 http，暴露端口号为 80，然后创建一个 service，名字为 front-end-svc，暴露该deployment 的 http 端口，并且 service 的类型为 NodePort。




```yaml
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
```

创建一个svc
```shell
kubectl expose deploy front-end --name=front-end-svc --port=80 \
--target-port=http --type=NodePort
```

## 9. Ingress考题 8%

- 参考地址: https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/

图示:
![](https://pic.imgdb.cn/item/63885c4916f2c2beb1fe8813.jpg)

环境准备:

```shell
[cka] root@master0:/home/lixie# k label node node1 ingress=true
node/node1 labeled
```


中文解释:

在 ing-internal 命名空间下创建一个 ingress，名字为 pong，代理的 service hi，端口为 5678，配置路径/hi。
验证：访问 curl -kL <INTERNAL_IP>/hi 会返回 hi

解题步骤:

```shell
$ k label node node2 ingress=true
$ k apply -f ingress.yaml
```

```yaml
[cka] root@master0:~/cka# cat 9-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pong   # 名称需要该
  namespace: ing-internal   # 需要该
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/hi"   # 访问路径需要改
        backend:
          service:
            name: front-end-svc   # 需要该
            port:
              number: 80
```


## 10. Sidecar 8%

图示:
![](https://pic.imgdb.cn/item/63885c4916f2c2beb1fe8813.jpg)

- 文章参考: https://kubernetes.io/zh-cn/docs/concepts/cluster-administration/logging/

中文解释:

添加一个名为 busybox 且镜像为 busybox 的 sidecar 到一个已经存在的名为 legacy-app 的
Pod 上，这个 sidecar 的启动命令为/bin/sh, -c, 'tail -n+1 -f /var/log/legacy-app.log'。

并且这个 sidecar 和原有的镜像挂载一个名为 logs 的 volume，挂载的目录为/var/log/

导出yaml

```yaml
[cka] root@master0:~/cka# cat 10-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: legacy-app
spec:
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
       while true;
       do
         echo "$(date) INFO $i" >> /var/log/legacy-app.log;
         i=$((i+1));
         sleep 1;
       done
       
首先将 legacy-app 的 Pod 的 yaml 导出，大致如下：
kubectl  get pod  legacy-app -o yaml > 10-2.yaml
```

进行修改

```yaml
[cka] root@master0:~/cka# cat 10-2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: legacy-app
  namespace: default
spec:
  containers:
  - name: busybox     # 需要修改
    image: busybox		# 需要修改
    args: [/bin/sh, -c, 'tail -n+1 -F /var/log/legacy-app.log']
    volumeMounts:
    - name: logs  # 需要修改
      mountPath: /var/log
  - args:
    - /bin/sh
    - -c
    - |
      i=0;
       while true;
       do
         echo "$(date) INFO $i" >> /var/log/legacy-app.log;
         i=$((i+1));
         sleep 1;
       done
    image: busybox
    imagePullPolicy: Always
    name: count
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:  # 需要添加
    - name: logs
      mountPath: /var/log
  volumes:
  - name: logs  # 需要修改
    emptyDir: {}
```


## 11.RBAC考题

- 文章参考: https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/

![](https://pic.imgdb.cn/item/63885c4916f2c2beb1fe8813.jpg)


中文解释:

创建一个名为 deployment-clusterrole 的 clusterrole，该 clusterrole 只允许创建 Deployment、
Daemonset、Statefulset 的 create 操作在名字为 app-team1 的 namespace 下创建一个名为 cicd-token 的 serviceAccount，并且将上一步创建 clusterrole 的权限绑定到该 serviceAccount

解题步骤:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" 被忽略，因为 ClusterRoles 不受名字空间限制
  name: deployment-clusterrole
rules:
- apiGroups: ["apps"]
  # 在 HTTP 层面，用来访问 Secret 资源的名称为 "secrets"
  resources: ["deployments","daemonsets","statefulsets"]
  verbs: ["create"]
```

创建serviceAccount:

```shell
$ k create ns  app-team1
$ k create sa cicd-token -n app-team1
$ k create rolebinding deployment-rolebinding \
--clusterrole='deployment-clusterrole' \
--serviceaccount=app-team1:cicd-token -n app-team1
```


## 12. NetworkPolicy 


图示:
![](https://pic.imgdb.cn/item/638876b716f2c2beb1265bf1.jpg)

中文解释:

创建一个名字为 allow-port-from-namespace 的 NetworkPolicy，这个 NetworkPolicy 允许internal 命名空间下的 Pod 访问该命名空间下的 9000 端口。并且不允许不是 internal 命令空间的下的 Pod 访问不允许访问没有监听 9000 端口的 Pod。

解题步骤:
```yaml
$ cat 12-1-cka.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: internal
spec:
  ingress:
  - from:
    - podSelector: {}
    ports:
    - port: 9000
      protocol: TCP
  podSelector: {}
  policyTypes:
  - Ingress
```

## 13. PersistentVolume 

- 文章参考: https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/


图示:

![](https://pic.imgdb.cn/item/63889f8016f2c2beb16c38d9.jpg)


中文解释:

创建一个 pv，名字为 app-config，大小为 2Gi，访问权限为 ReadWriteMany。Volume 的类型为 hostPath，路径为/srv/app-config


```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-config
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/srv/app-config"
```


## 14. CSI & PersistentVolumeClaim 


- 文章参考: https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-persistent-volume-storage/


图示:

![](https://pic.imgdb.cn/item/63889e2d16f2c2beb169fadc.jpg)


中文解释:

创建一个名字为 pv-volume 的 pvc，指定 storageClass 为 csi-hostpath-sc，大小为 10Mi

然后创建一个 Pod，名字为 web-server，镜像为 nginx，并且挂载该 PVC 至/usr/share/nginx/html，
挂载的权限为 ReadWriteOnce。之后通过 kubectl edit 或者 kubectl path 将 pvc 改成 70Mi，并且记录修改记录。


准备工作:

```shell
$ mkdir csi-hostpath
$ cd csi-hostpath

$ git clone https://gitee.com/dukuan/k8s-ha-install.git
$ cd k8s-ha-install/
$ git checkout manual-installation-v1.20.x-csi-hostpath

$ kubectl  create -f snapshotter/ 
$ kubectl get volumesnapshotclasses.snapshot.storage.k8s.io 
$ kubectl get volumesnapshots.snapshot.storage.k8s.io 
$ kubectl get volumesnapshotcontents.snapshot.storage.k8s.io
# 如果返回值不是error: the server doesn't have a resource type "volumesnapshotclasses"表示安装成功

# 有返回值说明Snapshot Controller已经安装
$ kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | grep snapshot-controller

$ 安装csi-hostpath
$ cd csi-hostpath/
$ kubectl apply -f .


$ 创建storageClass
$ cd examples/
$ kubectl  create -f csi-storageclass.yaml


```


解题步骤:

创建一个pvc
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-volume
spec:
  storageClassName: csi-hostpath-sc
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
```

创建一个pod挂在pvc

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  volumes:
    - name: pv-volume
      persistentVolumeClaim:
        claimName: pv-volume
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: pv-volume

```


```shell
kubectl patch pvc pv-volume -p '{"spec":{"resources":{"requests":{"storage": "70Mi"}}}}' --record
```


## 15. Etcd 备份恢复 

文章参考: https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/configure-upgrade-etcd/

![](https://pic.imgdb.cn/item/6388b21b16f2c2beb192e0d7.jpg)

中文解释: 

针对 etcd 实例 https://127.0.0.1:2379 创建一个快照，保存到/srv/data/etcd-snapshot.db。
在创建快照的过程中，如果卡住了，就键入 ctrl+c 终止，然后重试。
然后恢复一个已经存在的快照： /var/lib/backup/etcd-snapshot-previous.db
执行 etcdctl 命令的证书存放在：

- ca 证书：/opt/KUIN00601/ca.crt

- 客户端证书：/opt/KUIN00601/etcd-client.crt

- 客户端密钥：/opt/KUIN00601/etcd-client.key


解题步骤:

```shell

练习时需要查看证书的路径:
[cka] root@master0:/home/lixie# cat  /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.159.81:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.159.81:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt    # 指定 crt 文件
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.159.81:2380
    - --initial-cluster=master0=https://192.168.159.81:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key       # 指定 key 文件
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.159.81:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.159.81:2380
    - --name=master0
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt  # 指定证书文件
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```



这个证书的路径根据题目提供的写就可以了

备份:

```shell
apt  install etcd-client 
export ETCDCTL_API=3 
mkdir /srv/data/
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \ 
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /srv/data/etcd-snapshot.db

```

还原数据:
配置文件可能不在原来的位置,可以通过以下的方式来查找

![](https://pic.imgdb.cn/item/6389f82e16f2c2beb1418df6.jpg)

![](https://pic.imgdb.cn/item/6389f84916f2c2beb141c525.jpg)


模拟删除: (删除 pod 这样 etcd 的数据就会没有这个数据)

模拟还原:
```shell
mv /etc/kubernetes/manifests /etc/kubernetes/manifests.bak


export ETCDCTL_API=3 

etcdctl --endpoints=https://127.0.0.1:2379  --cacert=/etc/kubernetes/pki/etcd/ca.crt  --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot restore /src/data/etcd-snapshot.db  --data-dir=/var/lib/etcd-restore  --skip-hash-check


mv /etc/kubernetes/manifests.bak /etc/kubernetes/manifests
systemctl restart kubelet

```


## 16. k8s 升级

![](https://pic.imgdb.cn/item/638a113716f2c2beb172ddf3.jpg)


中文解释: 

仅需要升级 master 节点,和 kubelet,kubectl。不需要升级 etcd 等其他组件


解题步骤:

```shell
$ k cordon master0
$ k drain master0 --delete-emptydir-data --ignore-daemonsets --force

之后需要按照题目提示 ssh 到一个 master 节点

$ apt update
$ apt-cache policy kubeadm | grep 1.19.0 # (注意版本的差异，有可能并非 1.18.8
升级到 1.19) 
$ apt-get install kubeadm=1.19.0-00


# 验证升级计划
$ kubeadm upgrade plan
# 看到如下信息，可升级到指定版本
You can now apply the upgrade by executing the following command:
kubeadm upgrade apply v1.19.0

开始升级 Master 节点
kubeadm upgrade apply v1.20.9 --etcd-upgrade=false  # 注意这里不需要升级 etcd

升级kubelet和kubectl
apt-get install -y kubelet=1.19.0-00 kubectl=1.19.0-00
$ systemctl daemon-reload
$ systemctl restart kubelet
$ kubectl uncordon k8s-master

```


## 17. 集群故障排查 – kubelet 故障

![](https://pic.imgdb.cn/item/638a261016f2c2beb19c3246.jpg)

中文解释:

一个名为 wk8s-node-0 的节点状态为 NotReady，让其他恢复至正常状态，并确认所有的更改开机自动完成

```shell
$ ssh wk8s-node-0
$ sudo -i 
# systemctl status kubelet 
# systemctl start kubelet
# systemctl enable kubelet
```

## 变更题:

![](https://pic.imgdb.cn/item/639498b6b1fccdcd361e8c2a.jpg)

如果fubar没有打标签，需要打一个标签

```yaml
$ cat network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: my-app
spec:
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: fubar
      ports:
        - protocol: TCP
          port: 53
  ingress:
    - from:
        - podSelector: {}
      ports:
        - protocol: TCP
          port: 80
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```