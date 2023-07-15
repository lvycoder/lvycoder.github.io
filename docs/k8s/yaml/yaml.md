# **资源清单**


YAML 是 "YAML Ain't a Markup Language"（YAML 不是一种标记语言）的递归缩写。AML 的语法和其他高级语言类似，并且可以简单表达清单、散列表，标量等数据形态。它使用空白符号缩进和大量依赖外观的特色，特别适合用来表达或编辑数据结构、各种配置文件、倾印调试内容、文件大纲（例如：许多电子邮件标题格式和YAML非常接近）。
YAML 的配置文件后缀为 .yml，如：runoob.yml 。

基本语法：

- 大小写敏感
- 使用缩进表示层级关系
- 缩进不允许使用tab，只允许空格
- 缩进的空格数不重要，只要相同层级的元素左对齐即可
- '#'表示注释



###  **资源清单解读**
```yaml
apiVersion: v1         			#版本号，例如v1
kind: Pod       			 	#资源类型，如Pod
metadata:       			 	#元数据
  name: string         			# Pod名字
  namespace: string    			# Pod所属的命名空间
  labels:      					#自定义标签
    - name: string     			#自定义标签名字
  annotations:       			#自定义注释列表
    - name: string
spec:         							# Pod中容器的详细定义
  containers:      						# Pod中容器列表
  - name: string     					#容器名称
    image: string    					#容器的镜像名称
    imagePullPolicy: [Always | Never | IfNotPresent] #获取镜像的策略 Alawys表示下载镜像 IfnotPresent表示优先使用本地镜像，否则下载镜像，Nerver表示仅使用本地镜像
    command: [string]    					#容器的启动命令列表，如不指定，使用打包时使用的启动命令
    args: [string]     						#容器的启动命令参数列表
    workingDir: string     				#容器的工作目录
    volumeMounts:    							#挂载到容器内部的存储卷配置
    - name: string     			#引用pod定义的共享存储卷的名称，需用volumes[]部分定义的的卷名
      mountPath: string     #存储卷在容器内mount的绝对路径，应少于512字符
      readOnly: boolean     #是否为只读模式
    ports:       						# 需要暴露的端口库号
    - name: string        	    # 端口号名称
      containerPort: int        #容器需要监听的端口号
      hostPort: int             #容器所在主机需要监听的端口号，默认与Container相同
      protocol: string          #端口协议，支持TCP和UDP，默认TCP
    env:                        #容器运行前需设置的环境变量列表
    - name: string              #环境变量名称
      value: string             #环境变量的值
    resources:              #资源限制和请求的设置
      limits:               #资源限制的设置
        cpu: string         #cpu的限制，单位为core数
        memory: string      #内存限制，单位可以为Mib/Gib
      requests:             #资源请求的设置
        cpu: string         #cpu请求，容器启动的初始可用数量
        memory: string      #内存请求，容器启动的初始可用内存
    livenessProbe:          #对Pod内个容器健康检查的设置，当探测无响应几次后将自动重启该容器，检查方法有exec、httpGet和tcpSocket，对一个容器只需设置其中一种方法即可
      exec:                     #对Pod容器内检查方式设置为exec方式
        command: [string]       #exec方式需要制定的命令或脚本
      httpGet:                  #对Pod内个容器健康检查方法设置为HttpGet，需要制定Path、port
        path: string
        port: number
        host: string
        scheme: string
        HttpHeaders:
        - name: string
          value: string
      tcpSocket:                    #对Pod内个容器健康检查方式设置为tcpSocket方式
         port: number
       initialDelaySeconds: 0       #容器启动完成后首次探测的时间，单位为秒
       timeoutSeconds: 0            #对容器健康检查探测等待响应的超时时间，单位秒，默认1秒
       periodSeconds: 0             #对容器监控检查的定期探测时间设置，单位秒，默认10秒一次
       successThreshold: 0
       failureThreshold: 0
       securityContext:
         privileged:false
    restartPolicy: [Always | Never | OnFailure]#Pod的重启策略，Always表示一旦不管以何种方式终止运行，kubelet都将重启，OnFailure表示只有Pod以非0退出码退出才重启，Nerver表示不再重启该Pod
    nodeSelector: obeject           #设置NodeSelector表示将该Pod调度到包含这个label的node上，以key：value的格式指定
    imagePullSecrets:               #Pull镜像时使用的secret名称，以key：secretkey格式指定
    - name: string
    hostNetwork:false               #是否使用主机网络模式，默认为false，如果设置为true，表示使用宿主机网络
    volumes:                        #在该pod上定义共享存储卷列表
    - name: string                  #共享存储卷名称 （volumes类型有很多种）
      emptyDir: {}                  #类型为emtyDir的存储卷，与Pod同生命周期的一个临时目录。为空值
      hostPath: string              #类型为hostPath的存储卷，表示挂载Pod所在宿主机的目录
        path: string                #Pod所在宿主机的目录，将被用于同期中mount的目录
      secret:                       #类型为secret的存储卷，挂载集群与定义的secre对象到容器内部
        scretname: string  
        items:     
        - key: string
          path: string
      configMap:     #类型为configMap的存储卷，挂载预定义的configMap对象到容器内部
        name: string
        items:
        - key: string
          path: string
```

 [API和kubernetes的对应关系](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api_changes.md#alpha-beta-and-stable-versions)



### **rancher生产案例Yaml**
```yaml
####启动docker####

eval PROJECT_ID='$'$k8s_group
if [ $ms_group == 'center' ]
then
  replicas=1
else
  replicas=1
fi

/opt/rancher/rancher context switch $PROJECT_ID
cat <<EOF | /opt/rancher/rancher kubectl apply -f -
apiVersion: apps/v1           # 表示api版本，v1
kind: Deployment						  # kind表示资源类型，这里是Deployment
metadata:											# 元数据
  labels:
    workload.user.cattle.io/workloadselector: deployment-$name_space-$server_name
  name: $server_name					# 服务名
  namespace: $name_space			# 命名空间

spec:
  replicas: $replicas					Pod中容器的详细定义
  selector:
    matchLabels:
      workload.user.cattle.io/workloadselector: deployment-$name_space-$server_name
  template:
    metadata:
      labels:
        workload.user.cattle.io/workloadselector: deployment-$name_space-$server_name
    spec:
      imagePullSecrets:
      - name: old-harbor    # 镜像 仓库名
      restartPolicy: Always
      containers:
      - image: $harbor_addr/$name_space/$image_name:$image_tag  # 容器的镜像名
        imagePullPolicy: Always
        readinessProbe:
          failureThreshold: 60
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          tcpSocket:
            port: $NodePort         # 端口暴露方式
          timeoutSeconds: 1
        livenessProbe:
          failureThreshold: 3
          initialDelaySeconds: 300
          periodSeconds: 2
          successThreshold: 1
          tcpSocket:
            port: $NodePort
          timeoutSeconds: 1
        env:
        - name: CSProjFile
          value: $csproj_file
        - name: FOR_GODS_SAKE_PLEASE_REDEPLOY
          value: "`date +%s`"
        name: $server_name
        ports:
        - containerPort: $NodePort
        resources:
          requests:
            memory: $memory
        args: ["bash","-c","dotnet /opt/$csproj_file/$csproj_file.dll --serviceName $server_name \
        --webApiServiceAddress http://0.0.0.0:$NodePort --zkConfigServer $zk_configserver \
        --zkAppRole $zk_approle --runScope $run_scope --msGroup $ms_group \
        --KPversion 2 --psapp v2 --ser protobuf \
        --zkTimeOut 15000 --mcTimeOut 30000  --Cors *.xxxxx.net \
        --trace kafka --webApiHelp off $other_parameters"]
        # localtime
        volumeMounts:
        - mountPath: /etc/localtime
          name: localtime
          readOnly: true
      volumes:
      - hostPath:
          path: /etc/localtime
          type: ""
        name: localtime
---
apiVersion: v1
kind: Service
metadata:
  name: $server_name
  namespace: $name_space
spec:
  type: NodePort
  ports:
  - name: default
    nodePort: $NodePort
    port: $NodePort
    protocol: TCP
    targetPort: $NodePort
  selector:
    workload.user.cattle.io/workloadselector: deployment-$name_space-$server_name
EOF
```


### ** jenkins传数**

这里Jenkins作为上级项目，定义变量为下级项目传递参数

```shell
image_name=accountwebapiserver
name_space=webapi
server_name=account
csproj_file=AccountWebAPIServer
zk_approle=Common-AccountWebApi
Controller=account
run_scope=Core991
ms_group=$ms_group
zk_configserver=w1.confandsa.zk.group.hex.com:2181,w2.confandsa.zk.group.hex.com:2181,w3.confandsa.zk.group.hex.com:2181
image_tag=$image_tag
memory=1Gi
maxmemory=2.2Gi
NodePort=32037
k8s_group=$k8s_group
other_parameters=--UrlPrefix tms-zw4
```



### **第一个简单的容器化示例：**
```yaml
$ cat nginx-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-yyds
  namespace: web
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```


运行Yaml文件
```yaml
k apply -f nginx-deploy.yaml
```
查看pod的状态
```shell
$ k get pod
NAME                         READY   STATUS    RESTARTS   AGE
nginx-yyds-585449566-76hgr   1/1     Running   0          47m
nginx-yyds-585449566-vzwkw   1/1     Running   0          47m
```

### **常用的管理命令：**

查看控制器
```shell
$ k get deploy
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
nginx-yyds   2/2     2            2           51m
```

查看pod的详细信息

```shell
$ k get pod -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE    NOMINATED NODE   READINESS GATES
nginx-yyds-585449566-76hgr   1/1     Running   0          53m   10.42.2.130   node1   <none>           <none>
nginx-yyds-585449566-vzwkw   1/1     Running   0          53m   10.42.1.127   node0   <none>           <none
```

通过标签来查找pod
```shell
$ k get pod -l app=nginx
NAME                         READY   STATUS    RESTARTS   AGE
nginx-yyds-585449566-76hgr   1/1     Running   0          56m
nginx-yyds-585449566-vzwkw   1/1     Running   0          56m
```

```shell
$ k describe pod nginx-yyds-585449566-76hgr
Name:         nginx-yyds-585449566-76hgr
Namespace:    web
Priority:     0
Node:         node1/192.168.0.151
Start Time:   Tue, 23 Aug 2022 15:46:16 +0800
Labels:       app=nginx
              pod-template-hash=585449566
Annotations:  <none>
Status:       Running
IP:           10.42.2.130
IPs:
  IP:           10.42.2.130
Controlled By:  ReplicaSet/nginx-yyds-585449566
Containers:
  nginx:
    Container ID:   docker://7994248f600aa93444272eff8092938c866a5648db1126545d28635d41251b51
    Image:          nginx:latest
    Image ID:       docker-pullable://nginx@sha256:dc29f133a33a1d6311807f3b88134000ce67318a40517b1060b929b84b0bbea0
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 23 Aug 2022 15:48:42 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-rf7j8 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-rf7j8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  58m   default-scheduler  Successfully assigned web/nginx-yyds-585449566-76hgr to node1
  Normal  Pulling    58m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     55m   kubelet            Successfully pulled image "nginx:latest" in 2m24.557367751s
  Normal  Created    55m   kubelet            Created container nginx
  Normal  Started    55m   kubelet            Started container nginx
```

通过explain来查看Yaml文件写法
```shell
$ k explain
```