在 Kubernetes (K8s) 中，可以对 Pod 和 Container 设置资源限制，包括 CPU 和内存。这样可以防止某个 Pod 或 Container 占用过多的资源，影响到其他的 Pod 或 Container。

对于 CPU，可以设置的资源包括 `requests` 和 `limits`：

- `requests`：这是 Pod 启动所需要的最小 CPU 资源。Kubernetes 会确保 Pod 至少获得这么多的 CPU 资源。
- `limits`：这是 Pod 可以使用的最大 CPU 资源。Pod 的 CPU 使用量不会超过这个值。

对于内存，也可以设置 `requests` 和 `limits`：

- `requests`：这是 Pod 启动所需要的最小内存资源。Kubernetes 会确保 Pod 至少获得这么多的内存资源。
- `limits`：这是 Pod 可以使用的最大内存资源。如果 Pod 的内存使用量超过这个值，那么 Pod 可能会被系统 OOM Killer 杀掉。

以下是一个设置了资源限制的 Pod 定义示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: resource-demo-container
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "500m"
    ports:
    - containerPort: 8080
```

在这个示例中，`resource-demo-container` 这个 Container 的 CPU 使用量不会超过 500m（即半个 CPU 核心的使用量），内存使用量不会超过 200Mi。如果 Container 的 CPU 或内存使用量超过了这些值，Kubernetes 会采取相应的措施，例如限制 CPU 使用量，或者杀掉内存使用过多的 Pod。

注意，设置资源限制时，需要考虑到 Pod 的实际需求，避免设置过小导致 Pod 无法正常运行，也避免设置过大导致资源浪费。



CPU 以核心为单位，memory 以字节为单位。1核心=1000毫核

requests 为kubernetes scheduler执行pod调度时，node节点至少需要拥有的资源。

limit 为pod运行成功之后最多可以使用的资源上线


例子1: 以下是一个针对内存资源限制的yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limit-test-deployment
spec:
  replicas: 1
  selector:
    matchLabels: #rs or deployment
      app: limit-test-pod
#    matchExpressions:
#      - {key: app, operator: In, values: [ng-deploy-80,ng-rs-81]}
  template:
    metadata:
      labels:
        app: limit-test-pod
    spec:
      containers:
      - name: limit-test-container
        image: lorel/docker-stress-ng
        resources:
          limits:
            memory: "512Mi"
          requests:
            memory: "100Mi"
        #command: ["stress"]
        args: ["--vm", "2", "--vm-bytes", "256M"]
      #nodeSelector:
      #  env: group1
```

例子2: 以下是一个针对内存和CPU资源限制的yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limit-test-deployment
spec:
  replicas: 1
  selector:
    matchLabels: #rs or deployment
      app: limit-test-pod
#    matchExpressions:
#      - {key: app, operator: In, values: [ng-deploy-80,ng-rs-81]}
  template:
    metadata:
      labels:
        app: limit-test-pod
    spec:
      containers:
      - name: limit-test-container
        image: lorel/docker-stress-ng
        resources:
          limits:
            cpu: "1.2"
            memory: "512Mi"
          requests:
            memory: "100Mi"
            cpu: "500m"
        #command: ["stress"]
        args: ["--vm", "2", "--vm-bytes", "256M"]
      #nodeSelector:
      #  env: group1
```

一般通常来说，limits与request为相同大小，可以根据不同环境来修改。