# ConfigMap

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/config/configmap.md "编辑此页")

# ConfigMap

可变配置管理

前面我们学习了一些常用的资源对象的使用，但是单纯依靠这些资源对象，还不足以满足我们的日常需求，一个重要的需求就是应用的配置管理、敏感信息的存储和使用（如：密码、Token 等）、容器运行资源的配置、安全管控、身份认证等等。

对于应用的可变配置在 Kubernetes 中是通过一个 `ConfigMap` 资源对象来实现的，我们知道许多应用经常会有从配置文件、命令行参数或者环境变量中读取一些配置信息的需求，这些配置信息我们肯定不会直接写死到应用程序中去的，比如你一个应用连接一个 redis 服务，下一次想更换一个了的，还得重新去修改代码，重新制作一个镜像，这肯定是不可取的，而 `ConfigMap` 就给我们提供了向容器中注入配置信息的能力，不仅可以用来保存单个属性，还可以用来保存整个配置文件，比如我们可以用来配置一个 redis 服务的访问地址，也可以用来保存整个 redis 的配置文件。接下来我们就来了解下 `ConfigMap` 这种资源对象的使用方法。

## 创建

`ConfigMap` 资源对象使用 `key-value` 形式的键值对来配置数据，这些数据可以在 Pod 里面使用，如下所示的资源清单：
    
    
    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: cm-demo
      namespace: default
    data:
      data.1: hello
      data.2: world
      config: |
        property.1=value-1
        property.2=value-2
        property.3=value-3
    

其中配置数据在 `data` 属性下面进行配置，前两个被用来保存单个属性，后面一个被用来保存一个配置文件。

我们可以看到 `config` 后面有一个竖线符 `|`，这在 yaml 中表示保留换行，每行的缩进和行尾空白都会被去掉，而额外的缩进会被保留。
    
    
    lines: |
      我是第一行
      我是第二行
        我是吴彦祖
          我是第四行
      我是第五行
    
    # JSON
    {"lines": "我是第一行\n我是第二行\n  我是吴彦祖\n     我是第四行\n我是第五行"}
    

除了竖线之外还可以使用 `>` 右尖括号，用来表示折叠换行，只有空白行才会被识别为换行，原来的换行符都会被转换成空格。
    
    
    lines: >
      我是第一行
      我也是第一行
      我仍是第一行
      我依旧是第一行
    
      我是第二行
      这么巧我也是第二行
    
    # JSON
    {"lines": "我是第一行 我也是第一行 我仍是第一行 我依旧是第一行\n我是第二行 这么巧我也是第二行"}
    

除了这两个指令之外，我们还可以使用竖线和加号或者减号进行配合使用，`+` 表示保留文字块末尾的换行，`-` 表示删除字符串末尾的换行。
    
    
    value: |
      hello
    
    # {"value": "hello\n"}
    
    value: |-
      hello
    
    # {"value": "hello"}
    
    value: |+
      hello
    
    # {"value": "hello\n\n"} (有多少个回车就有多少个\n)
    

当然同样的我们可以使用`kubectl create -f xx.yaml`来创建上面的 `ConfigMap` 对象，但是如果我们不知道怎么创建 `ConfigMap` 的话，不要忘记 kubectl 是我们最好的帮手，可以使用`kubectl create configmap -h`来查看关于创建 `ConfigMap` 的帮助信息：
    
    
    Examples:
      # Create a new configmap named my-config based on folder bar
      kubectl create configmap my-config --from-file=path/to/bar
    
      # Create a new configmap named my-config with specified keys instead of file basenames on disk
      kubectl create configmap my-config --from-file=key1=/path/to/bar/file1.txt --from-file=key2=/path/to/bar/file2.txt
    
      # Create a new configmap named my-config with key1=config1 and key2=config2
      kubectl create configmap my-config --from-literal=key1=config1 --from-literal=key2=config2
    

我们可以看到可以从一个给定的目录来创建一个 `ConfigMap` 对象，比如我们有一个 testcm 的目录，该目录下面包含一些配置文件，redis 和 mysql 的连接信息，如下：
    
    
    ➜  ~ ls testcm
    redis.conf
    mysql.conf
    
    ➜  ~ cat testcm/redis.conf
    host=127.0.0.1
    port=6379
    
    ➜  ~ cat testcm/mysql.conf
    host=127.0.0.1
    port=3306
    

然后我们就可以使用 `from-file` 关键字来创建包含这个目录下面所以配置文件的 `ConfigMap`：
    
    
    ➜  ~ kubectl create configmap cm-demo1 --from-file=testcm
    configmap "cm-demo1" created
    

其中 `from-file` 参数指定在该目录下面的所有文件都会被用在 `ConfigMap` 里面创建一个键值对，键的名字就是文件名，值就是文件的内容。创建完成后，同样我们可以使用如下命令来查看 `ConfigMap` 列表：
    
    
    ➜  ~ kubectl get configmap
    NAME       DATA      AGE
    cm-demo1   2         17s
    

可以看到已经创建了一个 cm-demo1 的 `ConfigMap` 对象，然后可以使用 `describe` 命令查看详细信息：
    
    
    ➜  ~ kubectl describe configmap cm-demo1
    Name:         cm-demo1
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>
    
    Data
    ====
    mysql.conf:
    ----
    host=127.0.0.1
    port=3306
    
    redis.conf:
    ----
    host=127.0.0.1
    port=6379
    
    Events:  <none>
    

我们可以看到两个 `key` 是 testcm 目录下面的文件名称，对应的 `value` 值就是文件内容，这里值得注意的是如果文件里面的配置信息很大的话，`describe` 的时候可能不会显示对应的值，要查看完整的键值，可以使用如下命令：
    
    
    ➜  ~ kubectl get configmap cm-demo1 -o yaml
    apiVersion: v1
    data:
      mysql.conf: |
        host=127.0.0.1
        port=3306
      redis.conf: |
        host=127.0.0.1
        port=6379
    kind: ConfigMap
    metadata:
      creationTimestamp: 2018-06-14T16:24:36Z
      name: cm-demo1
      namespace: default
      resourceVersion: "3109975"
      selfLink: /api/v1/namespaces/default/configmaps/cm-demo1
      uid: 6e0f4d82-6fef-11e8-a101-525400db4df7
    

除了通过文件目录进行创建，我们也可以使用指定的文件进行创建 `ConfigMap`，同样的，以上面的配置文件为例，我们创建一个 redis 的配置的一个单独 `ConfigMap` 对象：
    
    
    ➜  ~ kubectl create configmap cm-demo2 --from-file=testcm/redis.conf
    configmap "cm-demo2" created
    ➜  ~ kubectl get configmap cm-demo2 -o yaml
    apiVersion: v1
    data:
      redis.conf: |
        host=127.0.0.1
        port=6379
    kind: ConfigMap
    metadata:
      creationTimestamp: 2018-06-14T16:34:29Z
      name: cm-demo2
      namespace: default
      resourceVersion: "3110758"
      selfLink: /api/v1/namespaces/default/configmaps/cm-demo2
      uid: cf59675d-6ff0-11e8-a101-525400db4df7
    

我们可以看到一个关联 redis.conf 文件配置信息的 `ConfigMap` 对象创建成功了，另外值得注意的是 `--from-file` 这个参数可以使用多次，比如我们这里使用两次分别指定 redis.conf 和 mysql.conf 文件，就和直接指定整个目录是一样的效果了。

另外，通过帮助文档我们可以看到我们还可以直接使用字符串进行创建，通过 `--from-literal` 参数传递配置信息，同样的，这个参数可以使用多次，格式如下：
    
    
    ➜  ~ kubectl create configmap cm-demo3 --from-literal=db.host=localhost --from-literal=db.port=3306
    configmap "cm-demo3" created
    ➜  ~ kubectl get configmap cm-demo3 -o yaml
    apiVersion: v1
    data:
      db.host: localhost
      db.port: "3306"
    kind: ConfigMap
    metadata:
      creationTimestamp: 2018-06-14T16:43:12Z
      name: cm-demo3
      namespace: default
      resourceVersion: "3111447"
      selfLink: /api/v1/namespaces/default/configmaps/cm-demo3
      uid: 06eeec7e-6ff2-11e8-a101-525400db4df7
    

## 使用

`ConfigMap` 创建成功了，那么我们应该怎么在 Pod 中来使用呢？我们说 `ConfigMap` 这些配置数据可以通过很多种方式在 Pod 里使用，主要有以下几种方式：

  * 设置环境变量的值
  * 在容器里设置命令行参数
  * 在数据卷里面挂载配置文件



首先，我们使用 `ConfigMap` 来填充我们的环境变量，如下所示的 Pod 资源对象：
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: testcm1-pod
    spec:
      containers:
        - name: testcm1
          image: busybox
          command: [ "/bin/sh", "-c", "env" ]
          env:
            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: cm-demo3
                  key: db.host
            - name: DB_PORT
              valueFrom:
                configMapKeyRef:
                  name: cm-demo3
                  key: db.port
          envFrom:
            - configMapRef:
                name: cm-demo1
    

这个 Pod 运行后会输出如下所示的信息：
    
    
    ➜  ~ kubectl logs testcm1-pod
    ......
    DB_HOST=localhost
    DB_PORT=3306
    mysql.conf=host=127.0.0.1
    port=3306
    redis.conf=host=127.0.0.1
    port=6379
    ......
    

我们可以看到 DB_HOST 和 DB_PORT 都已经正常输出了，另外的环境变量是因为我们这里直接把 cm-demo1 给注入进来了，所以把他们的整个键值给输出出来了，这也是符合预期的。

另外我们也可以使用 `ConfigMap`来设置命令行参数，`ConfigMap` 也可以被用来设置容器中的命令或者参数值，如下 Pod:
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: testcm2-pod
    spec:
      containers:
        - name: testcm2
          image: busybox
          command: [ "/bin/sh", "-c", "echo $(DB_HOST) $(DB_PORT)" ]
          env:
            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: cm-demo3
                  key: db.host
            - name: DB_PORT
              valueFrom:
                configMapKeyRef:
                  name: cm-demo3
                  key: db.port
    

运行这个 Pod 后会输出如下信息：
    
    
    ➜  ~ kubectl logs testcm2-pod
    localhost 3306
    

另外一种是非常常见的使用 `ConfigMap` 的方式：通过**数据卷** 使用，在数据卷里面使用 ConfigMap，就是将文件填入数据卷，在这个文件中，键就是文件名，键值就是文件内容，如下资源对象所示：
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: testcm3-pod
    spec:
      volumes:
        - name: config-volume
          configMap:
            name: cm-demo2
      containers:
        - name: testcm3
          image: busybox
          command: [ "/bin/sh", "-c", "cat /etc/config/redis.conf" ]
          volumeMounts:
          - name: config-volume
            mountPath: /etc/config
    

运行这个 Pod 的，查看日志：
    
    
    ➜  ~ kubectl logs testcm3-pod
    host=127.0.0.1
    port=6379
    

当然我们也可以在 `ConfigMap` 值被映射的数据卷里去控制路径，如下 Pod 定义：
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: testcm4-pod
    spec:
      volumes:
        - name: config-volume
          configMap:
            name: cm-demo1
            items:
            - key: mysql.conf
              path: path/to/msyql.conf
      containers:
        - name: testcm4
          image: busybox
          command: [ "/bin/sh","-c","cat /etc/config/path/to/msyql.conf" ]
          volumeMounts:
          - name: config-volume
            mountPath: /etc/config
    

运行这个Pod的，查看日志：
    
    
    ➜  ~ kubectl logs testcm4-pod
    host=127.0.0.1
    port=3306
    

另外需要注意的是，当 `ConfigMap` 以数据卷的形式挂载进 `Pod` 的时，这时更新 `ConfigMap（或删掉重建ConfigMap）`，Pod 内挂载的配置信息会热更新。这时可以增加一些监测配置文件变更的脚本，然后重加载对应服务就可以实现应用的热更新。

使用注意

只有通过 Kubernetes API 创建的 Pod 才能使用 `ConfigMap`，其他方式创建的（比如静态 Pod）不能使用；ConfigMap 文件大小限制为 `1MB`（ETCD 的要求）。
