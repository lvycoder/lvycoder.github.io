

## **云原生的定义**
[官方介绍:](https://github.com/cncf/toc/blob/main/DEFINITION.md#%E4%B8%AD%E6)

云原生技术有利于各组织在公有云、私有云和混合云等新型动态环境中，构建和运行可弹性扩展的应用。云原生的代表技术包括容器、服务网格、微服务、不可变基础设施和声明式API。
这些技术能够构建容错性好、易于管理和便于观察的松耦合系统。结合可靠的自动化手段，云原生技术使工程师能够轻松地对系统作出频繁和可预测的重大变更。
云原生计算基金会（CNCF）致力于培育和维护一个厂商中立的开源生态系统，来推广云原生技术。我们通过将最前沿的模式民主化，让这些创新为大众所用。

## **CNCF 云原生容器生态系统概要**

[官方介绍：](http://dockone.io/article/3006)

[CNCF 官网:](https://www.cncf.io/)

![20231008141630](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231008141630.png)

参考 kubecon 活动了解到一些最新的技术.以下是对一些技术的简单说明:

### **KubeBlocks**

- KubeBlocks创建基础设施: (可以帮助我们快速创建一个符合生产要求的数据库集群)
  - https://github.com/apecloud/kubeblocks#get-started-with-kubeblocks


![20231008141523](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231008141523.png)

 支持的附加组件:

 ![20231008141803](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231008141803.png)


### **OpenKruise**

OpenKruise 是一个基于 Kubernetes 的扩展套件，主要聚焦于云原生应用的自动化，比如 部署、发布、运维以及可用性防护。










### **学习文档：**

- www.qikqiak.com/k8strain

- www.qikqiak.com/k8strain2

- www.qikqiak.com/k3s

- [kubecon 会议: ](https://www.lfasiallc.com/kubecon-cloudnativecon-open-source-summit-china/) 

- [1-云计算课程笔记第一册-Linux系统管理](https://web-1311671045.cos.ap-beijing.myqcloud.com/1-%E4%BA%91%E8%AE%A1%E7%AE%97%E8%AF%BE%E7%A8%8B%E7%AC%94%E8%AE%B0%E7%AC%AC%E4%B8%80%E5%86%8C-Linux%E7%B3%BB%E7%BB%9F%E7%AE%A1%E7%90%86.pdf?sign=q-sign-algorithm%3Dsha1%26q-ak%3DAKIDttpksMNG0MSfgcpF_KGHGH5YiE_aVHfyXSq4hqIh7LgXscSij4a2uYDhK3Z-LxnW%26q-sign-time%3D1698646064%3B1698649724%26q-key-time%3D1698646064%3B1698649724%26q-header-list%3Dhost%26q-url-param-list%3D%26q-signature%3D19bf6eebc98897f2e00303ec6ed70cf69b2e3754&x-cos-security-token=sNun0ixmExZMC0G8tEBTW0JOEAq7ffiab0085b585d482ec7da35dc32abe230b857jY0T044k_5C2Z9bMgRrDugPmcvG4QC4BpZpDcPnwWP33lu5BFtzc0yy1MDyyWaGmoaEZp1kQvZ8_xEptpKMiwxsASWDfcK1GihQr-9cpQhDW5rTEHnY4-rzYUwvYu9qe-H-FWR8dIHke7dNTtTkgZJCmT4JjqmSKPuPGMU1t4vrH4zd4yvSz6Q040HtYKhPIPB9MB_AKdY-zUVvXZfrw)

- [2-云计算课程笔记第二册-Linux网络服务](https://web-1311671045.cos.ap-beijing.myqcloud.com/2-%E4%BA%91%E8%AE%A1%E7%AE%97%E8%AF%BE%E7%A8%8B%E7%AC%94%E8%AE%B0%E7%AC%AC%E4%BA%8C%E5%86%8C-Linux%E7%BD%91%E7%BB%9C%E6%9C%8D%E5%8A%A1.pdf?sign=q-sign-algorithm%3Dsha1%26q-ak%3DAKIDttpksMNG0MSfgcpF_KGHGH5YiE_aVHfyXSq4hqIh7LgXscSij4a2uYDhK3Z-LxnW%26q-sign-time%3D1698646064%3B1698649724%26q-key-time%3D1698646064%3B1698649724%26q-header-list%3Dhost%26q-url-param-list%3D%26q-signature%3Dcee9e6e4db8453a31975120196e0be8648c83832&x-cos-security-token=sNun0ixmExZMC0G8tEBTW0JOEAq7ffiab0085b585d482ec7da35dc32abe230b857jY0T044k_5C2Z9bMgRrDugPmcvG4QC4BpZpDcPnwWP33lu5BFtzc0yy1MDyyWaGmoaEZp1kQvZ8_xEptpKMiwxsASWDfcK1GihQr-9cpQhDW5rTEHnY4-rzYUwvYu9qe-H-FWR8dIHke7dNTtTkgZJCmT4JjqmSKPuPGMU1t4vrH4zd4yvSz6Q040HtYKhPIPB9MB_AKdY-zUVvXZfrw)

- [3-云计算课程笔记第三册-Shell脚本编程](https://web-1311671045.cos.ap-beijing.myqcloud.com/3-%E4%BA%91%E8%AE%A1%E7%AE%97%E8%AF%BE%E7%A8%8B%E7%AC%94%E8%AE%B0%E7%AC%AC%E4%B8%89%E5%86%8C-Shell%E8%84%9A%E6%9C%AC%E7%BC%96%E7%A8%8B.pdf?sign=q-sign-algorithm%3Dsha1%26q-ak%3DAKID5z6sWJ7-cxlQwQJq_Gsi-U8PRRsqc-pMqWYr5ORIV644h1p7dHhB-MA1UaPma14k%26q-sign-time%3D1698646433%3B1698650093%26q-key-time%3D1698646433%3B1698650093%26q-header-list%3Dhost%26q-url-param-list%3D%26q-signature%3D6ac61bb5e8f88bc1167d4cb4a989f956734c448b&x-cos-security-token=sNun0ixmExZMC0G8tEBTW0JOEAq7ffia75f7f0ecee96fdb5a5886b455e5ebeb057jY0T044k_5C2Z9bMgRrPoWhNOC-qtnqAOQkRjfE91pO9vUe-9V6KIlofzxIBj2eZqVidk2hMcNgJGG4hSBpntMvjBz5gLdI1NYlht7c8-exsMWeim9k2YLPmNTrgQR-6pZ6R1V6yrQeGTzc5vV_PjclNS0qkJCkd5Kt7gPuXpMMDgYsa9-CRF0zLAYHYZSG-dukUeuR069hfaETofkPw)

