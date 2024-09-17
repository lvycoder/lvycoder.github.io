# **Mysql-operator 安装部署**

!!! info "环境要求"
    - 安装Helm包管理工具
    - 安装rook-ceph作为后端存储
    - 安装operator
    - 安装mysql服务


## **安装**
  Helm和rook-ceph这里就不进行演示安装了，可以通过之前的文章来安装
    
### **安装operator **
github上有一个项目可以帮我们快速的来安装    [mysql](https://github.com/bitpoke/mysql-operator)

**优势:**

- 快速部署Mysql服务
- 解决了监控、可用性、可扩展性和备份问题
- 通过storageClass来解决存储问题
- 开箱即用的备份（计划和按需）和时间点恢复


#### 添加chart地址
```shell
helm repo add bitpoke https://helm-charts.bitpoke.io
helm repo update
```

#### 安装mysql-operator

```shell
$ helm install mysql-operator bitpoke/mysql-operator \
    -f 1-config.yaml \
    -n infra
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /Users/beiyiwangdejiyi/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /Users/beiyiwangdejiyi/.kube/config
NAME: mysql-operator
LAST DEPLOYED: Thu Aug 25 10:24:53 2022
NAMESPACE: infra
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You can create a new cluster by issuing:

cat <<EOF | kubectl apply -f-
apiVersion: mysql.presslabs.org/v1alpha1
kind: MysqlCluster
metadata:
  name: my-cluster
spec:
  replicas: 1
  secretName: my-cluster-secret
---
apiVersion: v1
kind: Secret
metadata:
  name: my-cluster-secret
type: Opaque
data:
  ROOT_PASSWORD: $(echo -n "not-so-secure" | base64)
EOF
```

这个1-config.yaml文件是给operator来使用的，这里定义了storageClass和容量
```shell
$ cat 1-config.yaml
orchestrator:
  persistence:
    enabled: true
    storageClass: "rook-ceph-block"
    accessMode: "ReadWriteOnce"
    size: 10Gi
```

验证：
```shell
$ k get pod
NAME                READY   STATUS    RESTARTS        AGE
mysql-operator-0    2/2     Running   2 (6m46s ago)   6m47s
```
这时，mysql-operator就安装好了，第二步就安装Mysql

### **安装mysql **

```shell
$ k apply -f 2-openbayes-mysql.yaml
secret/openbayes-db-secret created
mysqlcluster.mysql.presslabs.org/openbayes created
```


