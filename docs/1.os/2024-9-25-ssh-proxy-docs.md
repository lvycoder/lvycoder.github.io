
## SSH 转发代理

在工作中，常常会遇见一些恶心的环境，例如可以通过VPN的方式连接到客户的机器上，但是却无法上网。导致安装难度较大。
- 客户还会说：
  - 人们就应该来我们这里干活和出差......
  - 针对以上这种客户，只要我们可以连接上他们的linux机器，我们就可以同过ssh转发的代理的形式，让他们的机器上网。

## 实践操作

首先，我们需要指定一台ssh 转发的服务器。通过我们本地的Mac，来实现ssh的转发


#### 我的Mac电脑

```shell
# 这条命令主要的作用通过 SSH 隧道进行远程端口转发，并将本地的端口映射到远程服务器上（其中master.nb就是我们的远程服务器）
ssh -R 7890:localhost:7890 master.nb
```

通过以上的方式，我们就可以让我们的master.nb上网了。接下来是测试步骤(这个需要声明一下环境变量)

```shell
# 这个时候我们其实就能访问外网了
export http_proxy=http://127.0.0.1:7890 && export https_proxy=http://127.0.0.1:7890
curl https://openbayes.com/api/users/lixie/keys.txt
```

检查端口：（这个时候我们会显示7890端口只限制在了本地回环127.0.0.1上，也就是说和master.nb相同网段的机器无法通过master.nb代理出去）
![20240925161648](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20240925161648.png)

所以，很重要的两个参数配置 (修改master.nb /etc/ssh/sshd_config)
```
GatewayPorts yes
```
把监听端口127.0.0.1:7890绑定到 0.0.0.0:7890 地址上,这样外部的所有机器都能访问到这个监听端口，然后保存退出。重启ssh服务

![20240925162718](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20240925162718.png)


其他同网段的机器就可以通过这种方式来实现上网
```
[ningbo] root@gtx1070-1:/home/lixie# cat /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://master.nb:7890"
Environment="HTTPS_PROXY=http://master.nb:7890"
Environment="NO_PROXY=localhost,10.2.4.52"


[ningbo] root@gtx1070-1:/home/lixie# cat /etc/apt/apt.conf.d/02proxy
Acquire::http { Proxy "http://master.ningbo:nb" }
Acquire::https { Proxy "http://master.ningbo:nb" }
```