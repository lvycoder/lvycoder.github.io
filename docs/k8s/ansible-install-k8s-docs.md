针对本次乌兰察布上线，对ansible 脚本做了一些改动，主要来做自动化安装haproxy+keepliaved，并对配置做了一些自动化优化。一下是针对高可用画了一个简单的视图。
![20231102171508](https://barry-boy-1311671045.cos.ap-beijing.myqcloud.com/blog/20231102171508.png)

从图上可以看到，我们需要做的就是来配置 kubeadm,keepalived,haproxy; 以下是一个role的ansible配置

```shell
$ tree kube-lb
kube-lb
├── haproxy
│   ├── handlers
│   │   └── main.yml
│   ├── tasks
│   │   └── main.yml
│   └── templates
│       └── haproxy.cfg.j2
└── keepalived
    ├── tasks
    │   └── main.yml
    └── templates
        └── keepalived.conf.j2

7 directories, 5 files
```

首先可以看一个`haproxy.cfg.j2` 模版文件

```conf
frontend stats
    mode http
    bind *:58404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
    stats auth admin:Gj4QSrzxZcgmEnw

listen k8s_6443
  mode tcp
  bind *:56443
{% for host in groups['k8s_lb'] %} # 这个配置主要来循环inventory k8s_lb hosts 主机组
  server {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ hostvars[host]['ansible_default_ipv4']['address'] }}:6443 check inter 5s rise 2 fall 3
{% endfor %}

listen treafik_http
  mode tcp
  bind *:50443
{% for host in groups['k8s_lb'] %} # 打开k8s_lb主机组treafik UI
  server {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ hostvars[host]['ansible_default_ipv4']['address'] }}:443 check inter 5s rise 2 fall 3
{% endfor %}

listen treafik_https
  mode tcp
  bind *:50080
{% for host in groups['k8s_lb'] %} # 打开k8s_lb主机组treafik UI
  server {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ hostvars[host]['ansible_default_ipv4']['address'] }}:80 check inter 5s rise 2 fall 3
{% endfor %}
```

其次这个是针对`keepalived.conf.j2`做了一些自动化配置

```shell
{% for interface in vrrp_interfaces %}  # 对于 vrrp_interfaces 列表中的每个接口
vrrp_instance VI_1{{ loop.index }} {  # 创建一个名为 VI_1 加上当前循环索引的 VRRP 实例
    state {{ 'MASTER' if priority == 1 else 'BACKUP' }}  # 如果优先级为 1，则状态为 MASTER，否则为 BACKUP
    interface {{ interface }}  # 设置接口为当前循环的接口
    virtual_router_id 60  # 设置虚拟路由器 ID 为 60
    priority {{ 101 - priority }}  # 设置优先级为 101 减去当前优先级
    advert_int 2  # 设置广告间隔为 2 秒
    authentication {  # 设置认证
        auth_type PASS  # 认证类型为 PASS
        auth_pass 1111  # 认证密码为 1111
    }
    virtual_ipaddress {  # 设置虚拟 IP 地址
        {{ virtual_ipaddress }}  # 使用 virtual_ipaddress 变量
    }
    unicast_src_ip {{ node_ip }}  # 设置单播源 IP 为 node_ip
    unicast_peer {  # 设置单播对等体
    {%- for master in groups['k8s_lb'] %}  # 对于 groups['k8s_lb'] 列表中的每个 master
    {%- if master != inventory_hostname %}  # 如果 master 不等于 inventory_hostname
    {{- "\n    " + hostvars[master].node_ip }}  # 则添加 master 的 node_ip 到单播对等体列表
    {%- endif %}
    {%- endfor %}
    }  
}
{% endfor %}

```