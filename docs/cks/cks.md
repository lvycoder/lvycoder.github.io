# ***CKS考题***

## **1. 容器运行时（runtimeclass 考题）**

### **1.1.1 考题**



### **1.1.2 模拟考试环境**




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


#### 2022-01 考题更新




## **2. ServiceAccount考题**
!!! info "参考地址"
    - https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/



### **1.2.1 考题**



### **1.2.2 模拟考试环境**




### **1.2.3 考题解答**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-robot
automountServiceAccountToken: false
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: build-robot
  automountServiceAccountToken: false
```


## **3. kube-bench 考题**



### **1.3.1 考题**



### **1.3.2 模拟考试环境**




### **1.3.3 考题解答**



## **4. NetworkPolicy 考题**
!!! info "参考地址"
    - https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/


### **1.4.1 考题**



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
```


## **5. PSP 考题**

!!! info "参数地址"
    - https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-policy/



### **1.5.1 考题**



### **1.5.2 模拟考试环境**




### **1.5.3 考题解答**



## **6. RBAC 考题**


### **1.6.1 考题**



### **1.6.2 模拟考试环境**




### **1.6.3 考题解答**



## **7. 审计日志 考题**


### **1.7.1 考题**



### **1.7.2 模拟考试环境**




### **1.7.3 考题解答**