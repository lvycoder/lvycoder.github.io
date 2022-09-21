# **宁波港 ansible 配置**

!!! Warning "宁波港集群"
    - 宁波港集群没有外网，因此需要本地配置反向代理

##  **配置代理上网**

### **配置ssh配置文件**

修改 `/etc/ssh/sshd_config` 中 GatewayPorts yes，重新启动ssh服务


!!! Warning "配置代理"
    - 注意以下终端窗口不能关闭

打开命令行窗口
```
ssh -R 7890:localhost:7890 master.nb
```

了解更多ssh可以参考：[ssh配置](https://www.jianshu.com/p/01cb66fd83bb)

## **校验代理配置**

会在主机上做以下两个动作
```
[ningbo] root@gtx1070-1:/home/lixie# cat /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://master.ningbo:7890"
Environment="HTTPS_PROXY=http://master.ningbo:7890"
Environment="NO_PROXY=localhost,10.2.4.52"


[ningbo] root@gtx1070-1:/home/lixie# cat /etc/apt/apt.conf.d/02proxy
Acquire::http { Proxy "http://master.ningbo:7890" }
Acquire::https { Proxy "http://master.ningbo:7890" }
```

!!! info "ansible首次执行"
    - 在inventory中的hosts添加 
    ```
    node4.ucloud  hostname=node4 ansible_host=xxx.xxx.xxx.xxx ansible_ssh_user=ubuntu ansible_ssh_pass="password"
    ```

