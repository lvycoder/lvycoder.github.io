
# Ansible 概述

由于互联网的快速发展导致产品更新换代速度逐步增长，运维人员每天都要进行 大量的维护操作，按照传统方式进行维护使得工作效率低下。这时部署自动化运维就 可以尽可能安全、高效的完成这些工作。

Ansible 是基于 Python 开发，集合了众多优秀运维工具的优点，实现了批量运行 命令、部署程序、配置系统等功能的自动化运维管理工具。默认通过 SSH 协议进行 远程命令执行或下发配置，无需部署任何客户端代理软件，从而使得自动化环境部署 变得更加简单。可同时支持多台主机并行管理，使得管理主机更加便捷。

Ansible 可以看作是一种基于模块进行工作的框架结构，批量部署能力就是由 Ansible 所运行的模块实现的。简而言之 Ansible 是基于“模块”完成各种“任务”的。其 基本框架结构如图 3.1 所示。

![](https://pic1.imgdb.cn/item/6344343216f2c2beb1d78bd1.jpg)


由图 3.1 可以得出 Ansible 的基本架构由六大件构成。


- Ansible core 核心引擎：即 Ansible 本身；

- Host Inventory 主机清单：用来定义 Ansible 所管理主机，默认是在 Ansible 的 hosts 配置文件中定义被管理主机，同时也支持自定义动态主机清单和指定其它 配置文件的位置；

- Connect plugin 连接插件：负责和被管理主机实现通信。除支持使用 SSH 连接 被管理主机外，Ansible 还支持其它的连接方式，所以需要有连接插件将各个主 机用连接插件连接到 Ansible；

- Playbook（yaml，jinjia2）剧本：用来集中定义 Ansible 任务的配置文件，即将 多个任务定义在一个剧本中由 Ansible 自动执行，可以由控制主机针对多台被管 理主机同时运行多个任务；

- Core modules 核心模块：是 Ansible 自带的模块，使用这些模块将资源分发到被 管理主机使其执行特定任务或匹配特定的状态；

- Custom modules 自定义模块：用于完成模块功能的补充，可借助相关插件完成 记录日志、发送邮件等功能。



## **安装部署 Ansible 服务**



Ansible 自动化运维环境由控制主机与被管理主机组成。由于 Ansible 是基于 SSH 协议 进行通信的，所以控制主机安装 Ansible 软件后不需要重启或运行任何程序，被管理主机也 不需要安装和运行任何代理程序。


### **安装 Ansible**

- Centos 系统

Ansible 可以使用源码方式进行安装，也可以使用操作系统中 YUM 软件包管理工 具进行安装。 YUM 方式安装 Ansible，需要依赖第三方的 EPEL 源，下面配置 EPEL 源 作为部署 Ansible 的 YUM 源

```shell
[root@ansible-node1 ~]# yum install -y epel-release
[root@ansible-node1 ~]# yum install -y ansible

[root@ansible-node1 ~]# ansible --version   //查看ansible版本
```

- Mac 系统

[官方文章参考地址](https://formulae.brew.sh/formula/ansible)

这里一般我会使用Mac电脑作为ansible-server 来执行ansible脚本

```shell
brew install ansible
```



### **配置主机清单**

!!! tip "准备工作"
    - 配置inventory/pve
    ```shell
    [pve]
    master.pve hostname=master ansible_host=192.168.1.11 ansible_ssh_user=root ansible_ssh_pass="pass@word1"
    ```
这里首先我们先明白，每一个被控制的主机默认肯定会有一个帐号和密码，我们可以使用这个普通用户来对该主机进行一系列操作～

!!! warning "温馨提示"
    - 可能出现sudo权限不够的问题，那么可以在inventory添加以下内容
    ```shell
    gtx3090.c1 hostname=ubuntu ansible_ssh_user=xxx ansible_sudo_pass=xxx ansible_ssh_pass="password"
    ```

### **设置SSH无密码登陆**

如果上个步骤配置好，这个步骤可以忽略～
当然可以结合使用，具体场景还需要根据自己情况来配置


为了避免 Ansible 下发指令时需要输入被管理主机的密码，可以通过证书签名达到 SSH 无密码登录。使用 ssh-keygen 产生一对密钥，并通过 ssh-copy-id 命令来发送生成的公钥。



## **Ansible 命令应用基础**

Ansible 可以使用命令行的方式进行自动化管理。命令的基本语法如下所示：

```yaml
ansible  <host-pattern>   [-m module_name]   [-a args]
```


!!! info "Ansible 常用选项"
    - host-pattern：指定被管理主机
    - [-m module_name]：指定所使用的模块
    - [-a args]：设置模块对应的参数


    - -C  //预执行
    - --list-hosts //列出正在运行任务的主机
    - --list-tasks //列出tasks
    - --limit 主机列表 //只针对特定主机执行 


Ansible 的命令行管理工具都是由一系列模块、参数组成的，使用某些模块或参数之前， 可以在命令后面加上-h 或--help 来获取帮助。例如，ansible-doc 工具可以使用 ansible-doc -h 或者 ansible-doc --help 查看其帮助信息。


ansible-doc 工具用于查看模块帮助信息。主要选项包括：

-l 用来列出可使用的模块；
-s 用来列出某个模块的描述信息和使用示列。
例如：下面操作可以列出 yum 模块的描述信息和操作动作。

```shell
[root@ansible-node1 ~]# ansible-doc -s yum
```

---
Ansible 自带了很多模块，能够下发执行 Ansible 的各种管理任务。首先来了解下 Ansible 常用的这些核心模块。

探测模块:
```
$ ansible mac -m ping
cpu-4.mac | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
cpu-3.mac | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
cpu-1.mac | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```


### **1. command 模块**
Ansibale 管理工具使用-m 选项来指定所使用模块，默认使用 command 模块，即 -m 选 项省略时会运行此模块，用于在被管理主机上运行命令。例如在被管理主机上执行 date 命令，显示被管理主机时间。有三种执行命令的方式来管理写入主机清单中的主机。

示例一：使用 IP 地址查看被管理主机日期
```shell
$ ansible cka  -m command -a 'date' --limit cka.master
cka.master | CHANGED | rc=0 >>
Wed Oct 12 12:24:17 AM CST 2022

```

!!! warning "温馨提示"
    - 这里我使用的mac笔记本，使用的ansible-playbook，在仓库中有一个关于ansible.cfg的配置文件。
    ```shell
    $ cat ansible.cfg
    [defaults]
    pipelining = True
    strategy = free
    host_key_checking = False
    inventory = inventory  //这里主要的目录，主机清单文件位置
    library = library
    # gathering = smart
    fact_caching = redis
    # redis on stg-master
    fact_caching_connection = 106.75.63.184:3389:0:OpenBayesAnsibleCache
    fact_caching_timeout = 0
    forks = 16

    [privilege_escalation]
    become = True

    [diff]
    always = yes
    ```

示例二：使用管控主机分别查看被管理 cka-1 和 cka-2 组里面所有主机的日期

首先，需要准备主机文件
```shell
$ cat inventory/cka
[cka-1]
cka.master hostname=master0 ansible_host=172.30.42.244 ansible_user=lixie

[cka-2]
cka.node1  hostname=node1 ansible_host=172.30.192.106 ansible_user=lixie
cka.node2  hostname=node2 ansible_host=172.30.226.223 ansible_user=lixie
```


分组执行ansible 命令
```shell
$ ansible cka-1  -m command -a 'date'     //第一组
cka.master | CHANGED | rc=0 >>
Wed Oct 12 12:42:15 AM CST 2022
$ ansible cka-2  -m command -a 'date'     //第二组
cka.node1 | CHANGED | rc=0 >>
Wed Oct 12 12:38:55 AM CST 2022
cka.node2 | CHANGED | rc=0 >>
Wed Oct 12 12:38:55 AM CST 2022
```

当然了，如果上面的可以正确执行，那么其实命令也就是有手就行

**示例:**
```shell
$ ansible cka-2  -m command -a 'df -h'
```

示例三：查看所有被管理主机上的日期

```shell
[root@ansible-node1 ~]# ansible all -m command -a 'date
```


### **2. User 模块**

Ansible 中的 user 模块用于创建新用户和更改、删除已存在的用户。其中 name 选项用 于指明创建的用户名称。主要包括两种状态（state）：

- present 表示添加 (省略状态时默认使用)；
- absent 表示移除

示例一：在被管理组 cka-1 里所有主机上创建一个 user1 用户。

```shell
$ ansible cka-1 -m user -a 'name="user1"'
```

示例二：删除上述创建的用户 user1。

```shell
$ ansible cka-1 -m user -a 'name="user1" state=absent '
```

示例三: ansible创建用户并指定密码

生成加密密码
```shell
$ a=$(python3 -c 'import crypt,getpass;pw="pass@word";print(crypt.crypt(pw))')
$ echo $a
8e7klQ1BR7DIY
```

更新密码
```
$ ansible note1 -m user -a 'name=test password="$a" update_password=always'  //可以使用变量
$ ansible cka-1 -m user -a 'name="user1"  password=8e7klQ1BR7DIY update_password=always'
```



### **3. cron 模块**

Ansible 中的 cron 模块用于定义任务计划。主要包括两种状态（state）：

- present 表示添加 (省略状态时默认使用)

- absent 表示移除。



### **4. group 模块**

Ansible 中的 group 模块用于对用户组进行管理。

示例一：被管理组 cka-1 里所有主机创建 mysql 组，gid 为 555。

```shell
$ ansible cka-1 -m group -a 'name=mysql gid=555 system=yes'
```


示例二：将被管理组 cka-1 里所有主机的 mysql 用户添加到 mysql 组中。

```shell
ansible cka-1 -m user -a 'name=mysql uid=555 system=yes group=mysql'
```



### **5. copy 模块**

Ansible 中的 copy 模块用于实现文件复制和批量下发文件。其中使用 src 来定义本地源文件路径；使用 dest 定义被管理主机文件路径；使用 content 则是使用指定信息内容生成 目标文件。

示 例 一 ： 将本地文件 ucloud.yaml 复制到被管理组 cka-1 里的所有主机上的 /tmp/(当然也可以重命名)，并将所有者设置为 root，权限设置为 640。


```shell
$ ansible cka-1 -m copy -a 'src=ucloud.yaml dest=/tmp/ owner=root mode=640'
```

登录被管理主机，验证上述命令执行结果。

```shell
[cka] root@master0:/tmp# ll
total 44
drwxrwxrwt 10 root root 4096 Oct 12 10:37 ./
drwxr-xr-x 19 root root 4096 May 24 23:27 ../
-rw-r-----  1 root root 1172 Oct 12 10:33 ucloud.yaml
```


!!! warning "温馨提示"
    如果出现以下的报错信息，是因为被管理主机开启了 SELinux，需要在被管理机上安装 libselinux-python 软件包，才可以使用 Ansible 中与 copy、file 相关的函数。
    ```
    "msg": "Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!"
    ```

示例二：将”Hello Ansible Hi Ansible” 写入到被管理组 cka-1 里所有主机上的/tmp/ucloud.yaml 文件中。 当然这个例子我觉得很鸡肋～，注意这将完全替换ucloud.yaml里的文件内容


```shell
$ ansible cka-1 -m copy -a 'content="Hello Ansible Hi Ansible" dest=/tmp/ucloud.yaml'
```

登录被管理主机 cka-1，验证上述命令执行结果。


```shell
[cka] root@master0:/tmp# cat ucloud.yaml
Hello Ansible Hi Ansible
```

---



### **6. file 模块**

Ansible 中使用 file 模块来设置文件属性。其中使用 path 指定文件路径；使用 src 定义 源文件路径；使用 name 或 dest 来替换创建文件的符号链接。


示例一：设置被管理组 cka-1 里所有主机中/tmp/ucloud.yaml 文件的所属主为 mysql，所属组为 mysql，权限为 644。


```
$ ansible cka-1 -m file  -a 'owner=mysql group=mysql mode=644  path=/tmp/ucloud.yaml'
```

登录被管理主机，验证上述命令执行结果


```shell
[cka] root@master0:/tmp# ll
-rw-r--r--  1 mysql mysql   24 Oct 12 10:44 ucloud.yaml
```


### **7. ping 模块**

Ansible 中使用 ping 模块来检测指定主机的连通性。


示例：检测所有被管理主机的连通性。

```shell
$ ansible cka-1 -m ping

cka.master | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
cka.node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
cka.node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```



### **8. service 模块**

Ansible 中使用 service 模块来控制管理服务的运行状态。其中使用 enabled 表示是否 开机自动启动，取值为 true 或者 false；使用 name 定义服务名称；使用 state 指定服务状 态，取值有 started、stoped、restarted。

示例一：查看被管理组 cka-1 里所有主机 lxcfs 服务的状态。

```shell
$ ansible cka-1 -a 'systemctl status lxcfs'
```

示例二：查看被管理组 cka-1 里所有主机的 lxcfs 服务是否是开机自动启动状态。

```shell
$ ansible cka-1 -a 'systemctl is-enabled lxcfs'  
cka.node2 | CHANGED | rc=0 >>
enabled
cka.master | CHANGED | rc=0 >>
enabled
cka.node1 | CHANGED | rc=0 >>
enabled
```

启动被管理组里所有主机的 lxcfs 服务并且设置为开机自动启动状态。

```shell
ansible cka-1 -m service -a 'enabled=true name=lxcfs state=started'
```

启动被管理组里所有主机的 lxcfs 服务并且关闭为开机自动启动状态

```shell
$ ansible cka-1 -m service -a 'enabled=false name=lxcfs state=started'
```

---


### **9. shell 模块**
Ansible 中的 shell 模块可以在被管理主机上运行命令，并支持像管道符等功能的复杂命令。

示例一：被管理组 cka-1 里所有主机创建用户 user2，uid和gid 都为 1001，用 户家目录为/home/user1，shell 为/bin/bash。

```shell
$ ansible cka-1 -m user -a 'name=user2'
```

示例二：被管理组 cka-1 里的所有主机使用无交互模式给用户设置密码。

```shell
$ ansible cka-1 -m shell -a 'echo redhat|passwd --stdin user2'
$ ansible cka-1 -m shell -a  "echo 'user:tju_openbayes'|chpasswd"
```



示例三: 可以使用管道符

```shell
$ ansible cka-1 -m shell -a 'cat /etc/passwd |wc -l'
```


### **10. script 模块**

Ansible 中的 script 模块可以将本地脚本复制到被管理主机上进行运行。需要注 意的是使用相对路径指定脚本位置。

示例：编辑一个本地脚本 test.sh，复制到被管理组 cka-1 里所有主机上运行。

```shell
$ cat test.sh
#!/bin/bash
echo "hello tom" >> /tmp/1.txt  //准备一个测试脚本
chmod +x test.sh


$ ansible cka-1 -m script -a '../scripts/test.sh'
```

登录被管理主机,查看执行结果

```shell
[cka] root@master0:/tmp# cat 1.txt
hello tom
```

### **11. atp 模块**

Ansible 中的 apt模块负责在被管理主机上安装与卸载软件包，但是需要提前在每个节点配置自己的 apt 仓库。

- 使用 name 指定要安装的软件包，还可以带上软件包的版本号；否则安装最新的软件包

- 使用 state 指定安装软件包的状态，present、latest 用来表示安装，absent 表示卸载。

- update_cache=yes 当这个参数为yes的时候等于apt-get update

安装tree包

```shell 
$ ansible cka-1 -m apt -a 'name=tree update_cache=yes'
```

卸载tree包

```shell
$ ansible cka-1 -m apt -a 'name=tree state=absent'
```


### **12. yum 模块**

这里被控主机没有centos系统，就略～


### **13. setup 模块**


Ansible 中使用 setup 模块收集、查看被管理主机的 facts（facts 是 Ansible 采集 被管理主机设备信息的一个功能）。每个被管理主机在接收并运行管理命令之前，都 会将自己的相关信息（操作系统版本、IP 地址等）发送给控制主机。

```shell
$ ansible cka-1 -m setup
```



### **14. hostname 模块**
可以利用hostname 给主机修改主机名

```shell
$ ansible cka-1 -m hostname -a 'name=nginx01'
```


### **15. cron 模块**

```
$ ansible mac -m cron -a 'hour=2 minute=30 weekday=1-5 name="backup mysql" job=/root/lixie.sh' # 创建计划任务
$ ansible mac -m cron -a 'hour=2 minute=30 weekday=1-5 name="backup mysql" job=/root/lixie.sh disabled=yes' # 禁用计划任务
$ ansible mac -m cron -a 'hour=2 minute=30 weekday=1-5 name="backup mysql" job=/root/lixie.sh disabled=no' # 启用计划任务
$ ansible mac -m cron -a 'hour=2 minute=30 weekday=1-5 name="backup mysql" job=/root/lixie.sh state=absent' # 删除计划任务
$ ansible mac -m shell -a "crontab -l" # 查看计划任务


```

### **16. Lineinfile 模块**
允许你在文件中搜索特定的行，并在找到匹配项时替换它。如果没有找到匹配项，它将添加一个新的行


你可以使用Ansible的命令行方式来执行`lineinfile`模块。这是一个示例，它使用`ansible`命令来确保SELinux设置为强制模式：

```bash
ansible localhost -m lineinfile -a "path=/etc/selinux/config regexp='^SELINUX=' line='SELINUX=enforcing'"
```




















## **Ansible 案例**


#### **案例一：create_user.yaml**
!!! info "Ansible 批量创建用户"
    - 这里设置password需要使用python命令生成sha-512算法,pw是要加密的密码
    ```
    a=$(python3 -c 'import crypt,getpass;pw="123456";print(crypt.crypt(pw))')
    $ echo $a
    QUbhMQ9BAGQBE
    ```

!!! info "示例一 用户密码"
    ```yaml
    - hosts: pve
      tasks:
      - name: ensure admin group
        group:
          name: admin
          state: present

      - name: ensure admin group nopasswd sudo
        copy:
          dest: /etc/sudoers.d/admin
          content: |
            %admin ALL=(ALL:ALL) NOPASSWD: ALL


      - name: add user 
        user: name={{ item }}  groups=admin password=d6F1o2yfgTymU shell=/bin/bash 
        with_items:
          - user1
          - user2
          - user3
    ```

!!! info "示例二: 公钥形式"
    ```yaml
      tasks:
      - name: ensure admin group
        group:
          name: admin
          state: present

      - name: ensure admin group nopasswd sudo
        copy:
          dest: /etc/sudoers.d/admin
          content: |
            %admin ALL=(ALL:ALL) NOPASSWD: ALL

      - user:
          name: "{{ item }}"
          groups: admin
          shell: /bin/bash
        with_items:
          - lixie
      - user:
          name: "{{ item }}"
          state: absent
        with_items:
          - user
          # - ubuntu

      - authorized_key:
          user: "{{ item.u }}"
          key: "https://github.com/{{ item.k }}.keys"   # 公钥上传到github
        with_items:
          - {u: lixie, k: lixie021}
    ```

!!! Tip "执行ansible-playbook"
    ```
    ansible-playbook  -i inventory/pve  pve.yaml
    ```


官方参考文献: https://gist.github.com/alces/f7e3de25d98a19550a4e4f97cabc2cf4?from_wecom=1

```shell
ansible-playbook -i ucd-mysql, add-ssh-users.yml
```


### 附件

- ubuntu22.04 运行ansible报错

!!! error "ubuntu22.04 执行报错"
    ```shell
    TASK [Gathering Facts] *******************************************************************************************************
    fatal: [axis]: FAILED! => {"ansible_facts": {}, "changed": false, "failed_modules": {"ansible.legacy.setup": {"failed": true, "module_stderr": "/bin/sh: 1: /usr/bin/python: not found\n", "module_stdout": "", "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error", "rc": 127}}, "msg": "The following modules failed to execute: ansible.legacy.setup\n"}
    ```