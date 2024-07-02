# **Helm** 

## **Helm 简介**
Helm 可以帮助我们管理 Kubernetes 应用程序 - Helm Charts 可以定义、安装和升级复杂的 Kubernetes 应用程序，Charts 包很容易创建、版本管理、分享和分布.
简单可以理解Linux中yum的的感觉

## **Helm 安装**
!!! info "获取软件"
    官网地址：https://github.com/helm/helm/releases
下载到本地解压后，将 helm 二进制包文件移动到任意的 PATH 路径下
```
$ helm version
version.BuildInfo{Version:"v3.9.0", GitCommit:"7ceeda6c585217a19a1131663d8cd1f7d641b2a7", GitTreeState:"clean", GoVersion:"go1.18.2"}
```

Linux 下安装
```
root@k8s-master:/opt# wget https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz
cni  containerd  helm-v3.8.1-linux-amd64.tar.gz
root@k8s-master:/opt# tar -xf helm-v3.8.1-linux-amd64.tar.gz 
root@k8s-master:/opt/linux-amd64# mv helm /usr/bin/
```

## **管理配置**

### **Chart国内仓库配置 **

!!! info "仓库配置"
    - 微软的源：http://mirror.azure.cn/kubernetes/charts/ 
    - 阿里的源：https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts  
    - 官方的源：https://hub.kubeapps.com/charts/incubator

#### **添加chart存储库**

```
helm repo add stable  http://mirror.azure.cn/kubernetes/charts
helm repo add aliyun  https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

root@k8s-master:/opt/linux-amd64# helm repo update    # 更新源
```

#### **查看存储库**

```
$ helm repo list
NAME     	URL
stable   	http://mirror.azure.cn/kubernetes/charts/
openbayes	https://dev.openbayes.com/charts
```

#### **删除存储库**

```
root@k8s-master:/opt/linux-amd64# helm repo remove aliyun
```

## **Helm 部署应用:**

### **Helm 部署traefix**
!!! info "部署traefik"
    文章参考: https://github.com/traefik/traefik-helm-chart

```
git clone https://github.com/traefik/traefik-helm-chart.git
```

定义values文件

```yaml
$ cat sjtu-traefik.yaml
image:
  name: traefik
  tag: "2.7"
# values-prod.yaml
# Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    enabled: false  # 禁用helm中渲染的dashboard，我们自己手动创建

# Configure ports
ports:
  web:
    port: 8000
    hostPort: 80  # 使用 hostport 模式
    # Use nodeport if set. This is useful if you have configured Traefik in a
    # LoadBalancer
    # nodePort: 32080
    # Port Redirections
    # Added in 2.2, you can make permanent redirects via entrypoints.
    # https://docs.traefik.io/routing/entrypoints/#redirection
    # redirectTo: websecure
  websecure:
    port: 8443
    hostPort: 443  # 使用 hostport 模式

# Options for the main traefik service, where the entrypoints traffic comes
# from.
service:  # 使用 hostport 模式就不需要Service了
  enabled: false

# Logs
# https://docs.traefik.io/observability/logs/
#logs:
#  general:
#    level: DEBUG

tolerations:   # kubeadm 安装的集群默认情况下master是有污点，需要容忍这个污点才可以部署
- key: "node-role.kubernetes.io/master"
  operator: "Equal"
  effect: "NoSchedule"

nodeSelector:   # 固定到master1节点（该节点才可以访问外网）
  kubernetes.io/hostname: "master"
```


### 查看渲染结果

```
helm template -f ./values.yaml mysql . -n default > mysql.yaml
```

部署traefik
```
helm upgrade --install traefik traefik/traefik -f ./traefik/values/sjtu-traefik.yaml --namespace kube-system
```

查看这次部署
!!! info "温馨提示"
    这个是有命名空间限制的，-A 可以查看所有helm release

```yaml
$ helm list -A
NAME            	NAMESPACE          	REVISION	UPDATED                                	STATUS  	CHART                                                                                  	APP VERSION
traefik         	kube-system        	5       	2022-07-08 19:08:15.393244 +0800 CST   	deployed	traefik-10.24.0                                                                        	2.8.0
```



## **Helm 升级回滚**

### **升级**

!!! example "举例说明"

例如通过以下方式来升级grafana，也可以通过--set 在后面传参数
```
helm upgrade --install grafana  grafana/grafana 
```
!!! Warning "注意事项"
    在升级应用程序之前可以通过diff的方式来查看两个版本的区别，确定没问题，再升级
    ```
    $ helm diff  upgrade --install   grafana grafana/grafana -f  ./grafana.yaml -n infra
    ```
### **回滚**

```
helm rollback version-id
```
无论是升级还是回滚都是有一个的风险的，注意防止误操作。