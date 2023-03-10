
# Kuboard 介绍

Kuboard 是一款免费的 Kubernetes 管理工具，提供了丰富的功能，结合已有或新建的代码仓库、镜像仓库、CI/CD工具等，可以便捷的搭建一个生产可用的 Kubernetes 容器云平台，轻松管理和运行云原生应用。您也可以直接将 Kuboard 安装到现有的 Kubernetes 集群，通过 Kuboard 提供的 Kubernetes RBAC 管理界面，将 Kubernetes 提供的能力开放给您的开发/测试团队。Kuboard 提供的功能有：


![](https://pic.imgdb.cn/item/63a48e9608b68301633b61ca.jpg)


# 兼容性

![](https://pic.imgdb.cn/item/63a48ef008b68301633bc153.jpg)

# 安装

```shell
kubectl apply -f https://addons.kuboard.cn/kuboard/kuboard-v3.yaml
```

!!! warning "温馨提示"
    安装的时候我遇到服务跑不起来可以参考官网
    
    - https://kuboard.cn/install/v3/install-in-k8s.html#%E5%AE%89%E8%A3%85-2来调试

出现如图，两个服务都Running，那么就部署成功了！
![](https://pic.imgdb.cn/item/63a4900308b68301633d01b9.jpg)


## 访问 Kuboard

- 在浏览器中打开链接 http://your-node-ip-address:30080

- 输入初始用户名和密码，并登录

    - 用户名： admin

    - 密码： Kuboard123

![](https://pic.imgdb.cn/item/63a4905608b68301633d5850.jpg)

文章参考:

https://kuboard.cn/install/v3/install-in-k8s.html#%E5%AE%89%E8%A3%85