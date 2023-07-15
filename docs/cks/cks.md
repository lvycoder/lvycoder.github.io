# CKS考题

##  考题一：容器运行时（runtimeclass 考题）



### **1.1.1 考题**

![](https://pic.imgdb.cn/item/639f4135b1fccdcd363f480d.jpg)




### **1.1.2 模拟考试环境**
gvisor官网： https://gvisor.dev/docs/user_guide/install/

1. 首先，必须安装适当的依赖项以允许 apt 通过 https 安装软件包
```
sudo apt-get update && \
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg
```
2. 接下来，配置用于签署档案和存储库的密钥
```
curl -fsSL https://gvisor.dev/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | sudo tee /etc/apt/sources.list.d/gvisor.list > /dev/null
```

3. 现在可以安装runsc包了
```
sudo apt-get update && sudo apt-get install -y runsc
```

4. 配置containerd

```
[mac] root@cpu-1:/home/lixie# vim /etc/containerd/config.toml
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
            runtime_type = "io.containerd.runsc.v1"
[mac] root@cpu-1:/home/lixie# systemctl daemon-reload && systemctl restart containerd
```
5. 创建一个pod
```
$ kubectl create ns client
namespace/client created
$ kubectl run nginx --image=nginx -n client
pod/nginx created
```





### **1.1.3 考题解答**

!!! info "参考地址"
    - https://kubernetes.io/zh-cn/docs/concepts/containers/runtime-class/
#### 创建 RuntimeClass 资源

```yaml
# RuntimeClass 定义于 node.k8s.io API 组
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  # RuntimeClass 是一个集群层面的资源
  name: untrusted   # 用来引用 RuntimeClass 的名字
handler: runsc      # 对应的 CRI 配置的名称
```

#### 添加 runtimeClassName

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  runtimeClassName: untrusted  # 注意这个untrusted 名称
  # ...
```


```
kubectl get po nginx -n client -oyaml > nginx.yaml
kubectl delete -f nginx.yaml ; kubectl create -f nginx.yaml
```


#### 2022-01 考题更新

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jfs-app
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      runtimeClassName: untrusted # 注意更改之后的位置
      containers:
        - name: nginx
          image: nginx:latest
          imagePullPolicy: IfNotPresent
```


## **考题二：ServiceAccount考题**
!!! info "参考地址"
    - https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/



### **1.2.1 考题**

![](https://pic.imgdb.cn/item/64a68de31ddac507cc0c40f0.png)


### **1.2.2 模拟考试环境**

```
k create ns prod 
kubectl run backend -n prod --image=nginx --dry-run=client -oyaml > pod-manifests.yaml
```



### **1.2.3 考题解答**

官方文档： https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/



```
 kubectl create sa backend-sa -n prod --dry-run=client -oyaml > sa.yaml
```


```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: null
  name: backend-sa
  namespace: prod
automountServiceAccountToken: false # 不挂载 API 凭据
```

创建一个pod，并挂在serviceAccount

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: backend
  name: backend
  namespace: prod
spec:
  serviceAccountName: backend-sa # 挂载sa
  containers:
  - image: nginx
    name: backend
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
- 删除prod下其他没有使用的sa

```
kubectl delete sa default -n prod
```


## **考题三：kube-bench 考题**

Kube-Bench是一个用于检查和评估Kubernetes集群安全性的开源工具。它通过执行一系列的安全检查来评估Kubernetes集群的安全性配置，并提供相应的建议和指导来改善安全性。
### **1.3.1 考题**

![](https://pic.imgdb.cn/item/64a69def1ddac507cc329e04.jpg)

### **1.3.2 模拟考试环境**

```
[mac]  vim /etc/kubernetes/manifests/kube-apiserver.yaml
    - --authorization-mode=AlwaysAllow
    - --enable-bootstrap-token-auth=false
```

```
[mac]  vim /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: true
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: AlwaysAllow
```

```
vim /etc/kubernetes/manifests/etcd.yaml
- --client-cert-auth=false
```


安装 kube-bench：

```
wget https://github.com/aquasecurity/kube-bench/releases/download/v0.6.15/kube-bench_0.6.15_linux_amd64.deb
dpkg -i kube-bench_0.6.15_linux_amd64.deb

kube-bench
kube-bench master # 只检查master节点
```


### **1.3.3 考题解答**

ssh 到对应的节点上修改 kube-apiserver 配置：
```
vim /etc/kubernetes/manifests/kube-apiserver.yaml
    - --authorization-mode=Node,RBAC
```

修改etcd

```
vim /etc/kubernetes/manifests/etcd.yaml
- --client-cert-auth=true
```

修改kubelet

```
[mac]  vim /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false  # 改为false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook   # 改为Webhook
```

修改完成退出，修改node节点
```
systemctl daemon-reload && systemctl restart kubelet
```






## **考题四. NetworkPolicy 考题-默认拒绝所有ingress流量**
!!! info "参考地址"
    - https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/


### **1.4.1 考题**

![](https://pic.imgdb.cn/item/64a6a0c61ddac507cc39857e.jpg)

### **1.4.2 模拟考试环境**


### **1.4.3 考题解答**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: defaultdeny   # 名称可能不一样
spec:
  podSelector: {}
  policyTypes:
  - Ingress

k apply -f network-policy.yaml -n production
```


## **考题五：TLS通信配置**

!!! info "参数地址"
    - https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kube-apiserver/



### **1.5.1 考题**

文章参考：https://www.hao.kim/1112.html

修改API server和etcd之间通信的TLS配置
kube-apiserver除了 TLS 1.3 及以上的版本可以使用，其他版本都不允许使用。
密码套件（Cipher suite）为 TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256


### **1.5.2 模拟考试环境**


### **1.5.3 考题解答**
登录到master节点：
```
[mac] root@cpu-4:~# vim /etc/kubernetes/manifests/kube-apiserver.yaml
    - --tls-min-version=VersionTLS13
    - --tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

[mac] root@cpu-4:~# vim /etc/kubernetes/manifests/etcd.yaml
    - --cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

systemctl daemon-reload && systemctl restart kubelet
```

## **考题六. RBAC 考题**


### **1.6.1 考题**

![](https://pic.imgdb.cn/item/64a7b2731ddac507ccad8cf4.jpg)

### **1.6.2 模拟考试环境**

```
kubectl create ns monitoring
kubectl create sa service-account-web -n monitoring
```

创建 Role：
```
$ cat role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
 namespace: monitoring
 name: web-role
rules:
- apiGroups: [""] # "" 标明 core API 组
  resources: ["pods"]
  verbs: ["get", "watch", "list"]

kubectl create -f role.yaml
```
授权：
```
 kubectl create rolebinding pod-get --role=web-role --serviceaccount=monitoring:service-account-web -n monitoring
```
创建 Pod：
```
vim pod-rbac.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dev-pod
  name: dev-pod
  namespace: monitoring
spec:
  serviceAccountName: service-account-web
  containers:
  - image: nginx
    name: dev-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
# kubectl create -f pod-rbac.yaml
```

### **1.6.3 考题解答**

```
kubectl get po -n monitoring dev-pod -oyaml | grep serviceAccountName
kubectl  get rolebinding -n monitoring -oyaml |grep service-account-web -B 5
$ k edit  role web-role  -n monitoring
# 删除其他权限只留get
k apply -f role-sts-update.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: monitoring
  name: role-2
rules:
- apiGroups: ["extensions","apps"]
  resources: ["statefulsets"]
  verbs: ["update"]

kubectl create rolebinding role-2-binding --role=role-2 --serviceaccount=monitoring:service-account-web -n monitoring
```


## 变得题型


### 考题

编辑绑定到pod的 serviceaccount test-sa-3的现有role，仅允许只对endpoints类型的resources执行get操作
在namespace monitoring中创建一个名为role-2，并仅允许执行delete操作的新role
创建一个名为role-2-binding的新的rolebing，将role-2绑定道Pod绑定的serviceaccount 上

### 模拟考试环境



```
k create deploy nginx --image=nginx -n monitoring --dry-run=client -oyaml > role-new.yaml

k create sa test-sa-3 -n monitoring

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      serviceAccountName: test-sa-3 # 添加serviceAccountName
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}


kubectl create role web-role --verb=create --resource=deployments -n monitoring

kubectl create rolebinding web-role-binding --role=web-role --serviceaccount=monitoring:test-sa-3 -n monitoring
```


### 解题
```
查找绑定的Role（可能没有这个rolebinding，没有的话直接edit test-sa-3）
k get rolebinding -n monitoring -oyaml |grep test-sa-3 -B 5


k edit role web-role -n monitoring
- apiGroups:
  - ''   # 修改为空
  resources:
  - endpoints  # 修改
  verbs:
  - get # 修改


k create role role-2 --verb=delete --resource=namespaces -n monitoring
k create rolebinding role-2-binding --role=role-2 --serviceaccount=monitoring:test-sa-3 -n monitoring
```










## **7. 审计日志 考题**

官方文档：https://kubernetes.io/zh/docs/tasks/debug-application-cluster/audit/

### **1.7.1 考题**

![](https://pic.imgdb.cn/item/64a7c2281ddac507cce616e0.jpg)

### **1.7.2 模拟考试环境**


创建审计日志规则（切换 Context 后，ssh 到对应的 master 节点）：

```
mkdir -p /etc/kubernetes/logpolicy/ /var/log/kubernetes/ # 此步考试不用执行
```


### **1.7.3 考题解答**

```yaml
cat /etc/kubernetes/logpolicy/sample-policy.yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["cronjobs"]
  - level: Request
    resources:
    - group: ""
      resources: ["persistendvolumes"]
    namespaces: ["front-apps"]
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]
  - level: Metadata
    omitStages:
      - "RequestReceived"
```



```
vim /etc/kubernetes/manifests/kube-apiserver.yaml
 - --audit-policy-file=/etc/kubernetes/logpolicy/sample-policy.yaml
 - --audit-log-path=/var/log/kubernetes/kubernetes-logs.txt
 - --audit-log-maxage=30
 - --audit-log-maxbackup=10

```


```

考试环境：已经mount
    - mountPath: /var/log/kubernetes
      name: kubernetes-logs
    - mountPath: /etc/kubernetes/logpolicy
      name: kubernetes-policy
 name: kubernetes-policy
 hostNetwork: true
 priorityClassName: system-node-critical
 volumes:
  - hostPath:
      path: /etc/kubernetes/logpolicy
    name: kubernetes-policy
  - hostPath:
      path: /var/log/kubernetes
    name: kubernetes-logs


systemctl daemon-reload
systemctl restart kubelet
```
### 题目变更：

- 原题的第一个策略变成了：RequestResponse级别的nodes更改
- 第二个策略的namespace front-apps变成了webapps


## 考题八：k8s 凭据管理-secret


### 题目
![](https://pic.imgdb.cn/item/64a7d0181ddac507cc1334df.jpg)
### 模拟环境


```
kubectl create ns monitoring
kubectl create secret generic db1-test --from-literal=username=admin --from-literal=password=pass -n monitoring
```

### 考题解答

官网：https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/

查看 secret 内容：
```
kubectl get secret db1-test -n monitoring -oyaml | grep data -A 2 -m 1

# 解密后保存
mkdir /home/candidate
echo -n "YWRtaW4=" | base64 -d > /home/candidate/user.txt
echo -n "cGFzcw==" | base64 -d > /home/candidate/old-passwort.txt
```

创建 dev-mark Secret：
```
kubectl create secret generic  dev-mark  --from-literal=username=production-instance --from-literal=password=aV3qff3rqda -n monitoring 
```

创建pod：
```
kubectl run secret-pod -n monitoring --image=redis --dry-run=client -oyaml > secret-pod.yaml


apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: secret-pod
  name: secret-pod
  namespace: monitoring
spec:
  volumes:    
  - name: secret-volume
    secret:
      secretName: dev-mark
  containers:
  - image: redis
    name: secret-pod
    resources: {}
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/test-secret"
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```


## 考题九：Dockerfile和Deployment优化


### 考题
![](https://pic.imgdb.cn/item/64a7d8bf1ddac507cc2e7756.jpg)
### 模拟环境

```
cat /home/candidate/Dockerfile

FROM ubuntu:16.04
USER root
RUN apt get install -y nginx=4.2
ENV ENV=testing
USER root
CMD ["nginx -d"]
```


```
cat /home/candidate/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: test
  name: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: test
    spec:
      containers:
      - image: redis
        name: redis
        resources: {}
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
            drop: ["all"]
          privileged: true
          readOnlyRootFilesystem: false
          runAsUser: 65535

```


### 考题解答

- 优化Dockerfile
```
cat /home/candidate/Dockerfile

FROM ubuntu:16.04
USER nobody # 将roo天用户改为65535或者nobody
RUN apt get install -y nginx=4.2
ENV ENV=testing
USER nobody # 将roo天用户改为65535或者nobody
CMD ["nginx -d"]
```
- 优化deployment

```
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: test
  name: test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: test
    spec:
      containers:
      - image: redis
        name: redis
        resources: {}
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
            drop: ["all"]
          privileged: False # 关闭特权模式
          readOnlyRootFilesystem: True # 打开只读
          runAsUser: 65535

```

注意：如果 drop:那一项为空，需要改为 all


## 考题变更

SecurityContext 安全容器配置

### 考题

修改运行在namespaces app，名为lamp-deployment 的deployment，使其containerds

- 使用用户ID 30000 运行
- 使用一个只读的根文件系统
- 禁用 privilege escalation


```
[mac] root@cpu-4:~# kubectl create ns app
[mac] root@cpu-4:~# kubectl create deploy lamp-deployment --image=redis -n app
```

### 考题解答

```
kubectl edit deploy lamp-deployment -n app
      containers:
      - image: redis
        imagePullPolicy: Always
        name: redis
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsUser: 30000

# 如果有多个containers 需要都添加 securityContext 配置
```





## 考题十：无状态和不可变应用


### 考题
![](https://pic.imgdb.cn/item/64a7daa01ddac507cc34ccf5.jpg)

### 模拟环境

```yaml
kubectl create ns development

cat 11-pod-pri.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dev-pod
  name: dev-pod
  namespace: development
spec:
  containers:
  - image: nginx
    name: dev-pod
    resources: {}
    securityContext:
      privileged: true
  dnsPolicy: ClusterFirst
  restartPolicy: Always

k apply -f 11-pod-pri.yaml
```

### 考题解答

```
k get pod -n development -oyaml |grep -E "privileged|RootFileSystem"

# 检查挂载数据的pod
kubectl edit pod -n development
k delete pod dev-pod

# 删除具有特权的容器和以及挂载数据的容器
```

## 考题十一：NetworkPolicy 访问控制

### 考题

![](https://pic.imgdb.cn/item/64a7e1821ddac507cc4b5556.jpg)
### 模拟环境

```
kubectl create ns development
kubectl run products-service --image=nginx -n development
kubectl create ns qa
```

### 考题解答

官网：https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/

```
kubectl get ns qa --show-labels
kubectl get po products-service -n development --show-labels
k apply -f pod-restriction-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pod-restriction
  namespace: development
spec:
  podSelector:
    matchLabels:
      run: products-service
  policyTypes:
    - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          environment: testing
      namespaceSelector: {}
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: qa
```


## 考题十二： Trivy 扫描镜像安全漏洞 （3分）


### 考题

![](https://pic.imgdb.cn/item/64a961e71ddac507cc6dc46d.jpg)

### 模拟考题
```
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key |  sudo apt-key add -

echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list


wget https://github.com/aquasecurity/trivy/releases/download/v0.30.4/trivy_0.30.4_Linux-64bit.deb
dpkg -i trivy_0.30.4_Linux-64bit.deb


kubectl create ns kamino
kubectl run nginx --image=nginx -n kamino
kubectl run node --image=registry.cn-beijing.aliyuncs.com/dotbalo/node:v3.18.1 -n kamino
kubectl run alpine --image=alpine:3.14 -n kamino
```
### 考题解答
切换 Context 后，ssh 到对应的 master 节点
```
kubectl get pods -n kamino -o=custom-columns="NAME:.metadata.name,IMAGE:.spec.containers[*].image"

trivy image --skip-update -s "HIGH,CRITICAL" alpine:3.14

删除包含这些漏洞的镜像和pod
```

## 考题十三：禁止匿名访问 （6分）


### 考题
![](https://pic.imgdb.cn/item/64a9687f1ddac507cc7e2b57.jpg)


### 模拟环境



### 考题解答
切换context后，ssh到对应的master节点,更改context，ssh到对应的master节点
```
[mac] root@cpu-4:~# vim /etc/kubernetes/manifests/kube-apiserver.yaml
- --authorization-mode=Node,RBAC
- --enable-admission-plugins=NodeRestriction
```

删除 clusterrolebinding：
```
kubectl delete clusterrolebinding system:anonymous
```


## 考题十四：AppArmor （12分）

### 考题

官方文档：https://kubernetes.io/docs/tutorials/security/apparmor/

![](https://pic.imgdb.cn/item/64a971e01ddac507cc963b53.jpg)
### 模拟环境

Node 节点安装 AppArmor：
```
 apt-get install apparmor-utils -y
 apparmor_status
```
创建 AppArmor 限制文件：
```
root@cks-node:~# vim /etc/apparmor.d/nginx_apparmor
#include <tunables/global>

profile nginx-profile-1 flags=(attach_disconnected) {
  #include <abstractions/base>

  file,

  # Deny all file writes.
  deny /** w,
}
```
Master 节点创建 deploy 文件:
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-deploy
spec:
  containers:
  - name: nginx-deploy
    image: busybox:1.28
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

### 考题解答

切换 Context，ssh 到 node 节点进行操作

加载 apparmor 配置文件：
```
apparmor_parser /etc/apparmor.d/nginx_apparmor
```
查看 apparmor 的策略名称：
```
apparmor_status | grep nginx-profile
```

```
kubectl create -f nginx-deploy.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-deploy
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx-deploy:  localhost/nginx-profile-1  # 增加一个注解
spec:
  containers:
  - name: nginx-deploy
    image: busybox:1.28
    command: [ "sh", "-c", "echo 'Hello AppArmor!' && sleep 1h" ]
```

## 考题十五：sysdig

### 考题
![](https://pic.imgdb.cn/item/64a9760e1ddac507cc9f637c.jpg)
### 模拟环境

- 在工作节点安装 sysdig：

```
curl -s https://s3.amazonaws.com/download.draios.com/stable/install-sysdig |bash
kubectl run redis --image=redis
```

### 考题解答

- 切换 Context 后，ssh 到对应的工作节点
```
查看容器的名字或 ID: docker ps |grep redis
没有 Docker 命令:  crictl ps | grep redis
如果既没有 Docker 命令也没有 crictl 命令： kubectl get po redis -oyaml | grep containerID
```
使用 sysdig 进行检测：
```
sudo sysdig -M 30 -p "%evt.time,%user.uid,%proc.name" container.id=46183d7281e15 > /opt/KSRS00101/events/details
```
注意：如果文件为空，使用 container.name 重新执行
```
sudo sysdig -M 30 -p "%evt.time,%user.uid,%proc.name" container.name=redis > /opt/KSRS00101/events/details
```


## 考题十六：ImagePolicyWebhook

![](https://pic.imgdb.cn/item/64aa50981ddac507ccef72e7.jpg)

### 模拟环境

上传 cfssl 和 cfssljson 并更改权限：
```
# mv cfssl_linux-amd64 /usr/local/bin/cfssl
chmod +x /usr/local/bin/cfssl
# mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssljson
```

生成 ImagePolicyWebhook 所用的证书：

```
cat <<EOF | cfssl genkey - | cfssljson -bare server
{
 "hosts": [
   "wakanda.local",
   "wakanda.local.default.svc",
   "wakanda.local.default.svc.cluster.local",
   "wakanda.local.default.pod.cluster.local"
 ],
 "CN": "system:node:image-bouncer-webhook.default.pod.cluster.local",
 "key": {
   "algo": "ecdsa",
   "size": 256
 },
 "names": [
   {
     "O": "system:nodes"
   }
 ]
}
EOF
```

创建一个 CSR：

```
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: wakanda.local
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
```

```
kubectl get csr
kubectl certificate approve wakanda.local
kubectl get csr wakanda.local -o jsonpath='{.status.certificate}' | base64 --decode > server.crt
cp server.crt /etc/kubernetes/pki/
echo "127.0.0.1 wakanda.local" >> /etc/hosts

```

创建准入控制器的配置文件：
```
mkdir /etc/kubernetes/epconfig/
vim /etc/kubernetes/epconfig/admission_configuration.json
{
  "imagePolicy": {
    "kubeConfigFile": "/etc/kubernetes/epconfig/kubeconfig.yaml",
    "allowTTL": 50,
    "denyTTL": 50,
    "retryBackoff": 500,
    "defaultAllow": true
  }
}

```

创建 kubeconfig：
vim /etc/kubernetes/epconfig/kubeconfig.yaml

```
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/server.crt
    server: 
  name: bouncer_webhook
contexts:
- context:
    cluster: bouncer_webhook
    user: api-server
  name: bouncer_validator
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key

```


安装 Docker（https://docs.docker.com/engine/install/ubuntu/）：

```
apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install docker-ce docker-ce-cli

```
启动 ImagePolicyWebHook 服务器：
```
chmod 777 *

docker run -tid --rm \
  -v `pwd`/server-key.pem:/certs/server-key.pem:ro \
  -v `pwd`/server.crt:/certs/server.crt:ro \
  -p 8082:1323 \
  registry.cn-beijing.aliyuncs.com/dotbalo/kube-image-bouncer \
  -k /certs/server-key.pem \
  -c /certs/server.crt

```

```
mkdir /root/KSSC00202/
cat /root/KSSC00202/configuration-test.yml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-latest
spec:
  replicas: 1
  selector:
    app: nginx-latest
  template:
    metadata:
      name: nginx-latest
      labels:
        app: nginx-latest
    spec:
      containers:
      - name: nginx-latest
        image: nginx
        ports:
        - containerPort: 80

```

### 考题解答

切换 Context 后，ssh 到对应的 master 节点

- 关闭默认允许：
```
vim /etc/kubernetes/epconfig/admission_configuration.json
'defaultAllow': false  # 将true 改成 false
```
- 配置 Webhook 地址：

```
vim /etc/kubernetes/epconfig/kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/server.crt
    server: https://acme.local:8082/image_policy # 增加webhook server
  name: bouncer_webhook
contexts:
- context:
    cluster: bouncer_webhook
    user: api-server
  name: bouncer_validator
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/pki/apiserver.crt
    client-key: /etc/kubernetes/pki/apiserver.key
```
- 开启 ImagePolicyWebhook：

```
 vim /etc/kubernetes/manifests/kube-apiserver.yaml
 - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
 - --admission-control-config-file=/etc/kubernetes/epconfig/admission_configuration.json
```

```
在 volumeMounts 增加   
 
volumeMounts:   
    - mountPath: /etc/kubernetes/epconfig
      name: epconfig 
 
在volumes 增加
volumes: 
  - name: epconfig
    hostPath:
      path: /etc/kubernetes/epconfig
```

重启kubelet服务
```
systemctl daemon-reload  && systemctl restart kubelet
```