
## **SSH 转发代理**

在工作中，常常会遇见一些恶心的环境，例如可以通过VPN的方式连接到客户的机器上，但是却无法上网。导致安装难度较大。

- 客户还会说：
  - 人们就应该来我们这里干活和出差......
  - 针对以上这种客户，只要我们可以连接上他们的linux机器，我们就可以同过ssh转发的代理的形式，让他们的机器上网。(实现一些骚操作)


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



### 演示测试:

```
$ ip route del default via 10.0.10.1 dev ens33 proto static # 删除本地的默认路由,这样模拟无法上网的环境

# 我们需要声明将代理指向代理服务器.我们就能实现上网,甚至是翻墙
[cpu] root@nfs-server:~# export http_proxy=http://{proxy-ip-address}:7890
[cpu] root@nfs-server:~# export https_proxy=http://{proxy-ip-address}:7890
[cpu] root@nfs-server:~# curl https://openbayes.com/api/users/lixie/keys.txt
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDwWSc73tyq4TAkXxt3rWmGggbpgdm+egc8mOSDu0hauuvPdieIe1qUbKsIKC1O93KyDPlsfP5gcwqdEmf5Di0S6CCxRh6ENyZ9mtN+s1pCDeHiKbjhPyG4o71tafIDOjhcbpEtCwPA0YTrp5i1oO466qYHeFmTCmkcDFhuEKZx78EZdTwbFH0vhOGTymLFgUVauzmd45ZxpTzaZHrd093nFHWg6FeZWk2axkDiijLALNxiAAaECn2S69y5SxXgKSqpe4Z25b2cKKySlM1lBv1eI7CSxAUoxuXSpcgoRiVUx5VgJwkixKvq8NpihYEkV5pFRjB8W0ssu1YF6d+3MlzOkwa+kir9JJlLq+F/rrBTfF2mCLBgg0KE+voDd8vjEkqSmweNs2gEO7Gi/fUEfcabNAOuNNPL2dhdFl+BH2TCofDYvZcWd8Wrl/0qoW5nbUdCaC7aznb0lpVgseB/gj6ah3adCzfA/W8S+1znD9VMHDdMNy+AN8eeQQ6d2t05SOc=[cpu] root@nfs-server:~#
```


### 案例

主要的改动其实就是以下两个地方，其他同网段的机器就可以通过这种方式来实现上网
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

## Ansible自动化配置

以上的脚本可以通过ansible来自动化的，配置上，这样所有的节点就都可以上网了。(这个脚本可以帮组我们来配置apt，docker的proxy)

```yaml
- name: Gather facts about the system
  ansible.builtin.setup:

- name: Check if Docker is installed
  command: docker --version
  register: docker_installed
  ignore_errors: true

- name: Ensure the Docker proxy directory exists (only if Docker is installed)
  file:
    dest: /etc/systemd/system/docker.service.d
    state: directory
  when: docker_installed.rc == 0

- name: Add Docker proxy settings (only if Docker is installed)
  copy:
    directory_mode: yes
    dest: /etc/systemd/system/docker.service.d/http-proxy.conf
    content: |
      [Service]
      Environment="HTTP_PROXY={{ http_proxy }}"
      Environment="HTTPS_PROXY={{ https_proxy }}"
      Environment="NO_PROXY={{ no_proxy }}"
  when: docker_installed.rc == 0

- name: Reload Docker (only if Docker is installed)
  service:
    name: docker
    state: restarted
    daemon_reload: yes
  when: docker_installed.rc == 0

- name: Add proxy for apt
  copy:
    dest: /etc/apt/apt.conf.d/02proxy
    content: |
      Acquire::http { Proxy "{{ http_proxy }}" }
      Acquire::https { Proxy "{{ https_proxy }}" }
```
