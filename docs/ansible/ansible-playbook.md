
## **playbook 配置文件** 

Playbook配置文件使用YAML语法，具有简介明了，结构清晰等特点。Playbook配置文件类似于shell脚本，是一个YAML格式的文件，用于保存针对特定需求的任务列表，前面介绍的ansible命令虽然可以完成各种任务，但是当配置一系列任务时，逐条输入命令就显得效率非常低下，更有效的方式在playbook配置中配置所有的任务代码，利用ansible-playbook命令执行该文件，可以实现自动化运维，YAML文件的扩展名通常为.yaml或.yml。
YAML语法和其他高级语言类似，其结构通过缩进来展示，通过“-”来代表选项，通过冒号“：”来分隔键和值。整个文件以“---”开始并以“…”结束，如下所示

修改hosts文件

```
[root@ansible ~]# vim /etc/ansible/hosts
[test01]
192.168.200.112
[test02]
192.168.200.113

[root@ansible ~]# vim /etc/ansible/test.yml
---
- hosts: test01
  remote_user: root 
  tasks:
    - name: adduser
      user: name=user2 state=present
      tags:
      - testaaa
    - name: addgroup
      group: name=root system=yes
      tags:
      - testbbb

- hosts: test02
  remote_user: root
  tasks:
    - name: copy file
      copy: src=/etc/passwd dest=/home
      tags:
      - testccc

```

注释:
```
[root@ansible ~]# vim /etc/ansible/test.yml	//创建test，yml文件
---										//开头格式（可忽略）
- hosts:  test01							//表示对test01（192.168.200.112）的操作
  remote_user:  root						//远端执行用户身份root
  tasks:									//任务列表
    - name: adduser						//任务名称
      user: name=user2 state=present		//执行user模块创建用户
      tags: 								//创建tag标签
        - testaaa							//tag标签为testaaa
    - name: addgroup						//任务名称
      group: name=root system=yes			//执行group模块创建组
      tags:								//创建tag标签
       - testbbb							//tag标签为testbbb
- hosts：test02							//表示对test02（192.168.200.113）的操作
  remote_user: root						//远端执行用户身份root
  tasks:								    //任务列表
    - name: copy file to test					//任务名称
      copy: src=/etc/passwd dest=/home		//执行copy模块复制文件
      tags: 								//创建tag标签
       - testccc							//tag标签为testccc
...    									//结尾格式（可忽略）
```

所有的“-”和“：”后面均有空格，而且要注意缩进和对齐


### **Playbook的核心元素包含：**

1. hosts：任务的目标主机，多个主机用冒号分隔，一般调用/etc/ansible/hosts中的分组信息   
2. remote_user:远程主机上，运行此任务的什么默认为root
3. tasks：任务，即定义的具体任务，由模块定义的操作列表
4. handlers：触发器，类似tasks，只是在特定的条件下才会触发任务。某任务的状态在运行后为changed时，可通过“notify”通知给相应的handlers进行触发执行。
5. roles：角色，将hosts剥离出去，由tasks，handlers等所组成的一种特定的结构集合。


```
1. --syntax-check:检测yaml文件的语法
2. -C（--check）：测试，不会改变主机的任何配置
3. --list-hosts:列出yaml文件影响的主机列表
4. --list-tasks：列出yaml文件的任务列表
5. --list-tags:列出yaml文件中的标签
6. -t TAGS (--tags=TAGS):表示只执行指定标签的任务
7. --skip-tags=SKIP_TAGSS:表示除了指定标签任务，执行其他任务
8. --start-at-task=START_AT:从指定任务开始往下运行
```

实验案例:
```
[root@ansible ~]# ansible-playbook --syntax-check /etc/ansible/test.yaml
playbook: /etc/ansible/test.yml				//没有报错提示
```

```
预测试:
[root@ansible ~]# ansible-playbook -C /etc/ansible/test.yaml 

列出任务:
$ ansible-playbook --list-tasks /etc/ansible/test.yml 
// 只执行cpu-3.mac 主机上tag为testccc
$ ansible-playbook -i inventory/mac test_tag.yml --tag testccc --limit cpu-3.mac 


列出标签:
[root@ansible ~]# ansible-playbook --list-tags /etc/ansible/test.yml 

执行任务:
[root@ansible ~]# ansible-playbook /etc/ansible/test.yml


列出主机:
$ ansible mac --list
  hosts (3):
    cpu-1.mac
    cpu-3.mac
    cpu-4.mac
$ ansible mac --list-hosts
  hosts (3):
    cpu-1.mac
    cpu-3.mac
    cpu-4.mac

```



## **Ansible playbook:**



### **1. 执行配置文件**

Playbook配置文件使用YAML语法，具有简介明了，结构清晰等特点。Playbook配置文件类似于shell脚本，是一个YAML格式的文件，用于保存针对特定需求的任务列表，前面介绍的ansible命令虽然可以完成各种任务，但是当配置一系列任务时，逐条输入命令就显得效率非常低下，更有效的方式在playbook配置中配置所有的任务代码，利用ansible-playbook命令执行该文件，可以实现自动化运维，YAML文件的扩展名通常为.yaml或.yml。
YAML语法和其他高级语言类似，其结构通过缩进来展示，通过“-”来代表选项，通过冒号“：”来分隔键和值。整个文件以“---”开始并以“…”结束，如下所示


### **2. 触发器**

需要触发才能执行的任务，当之前定义在tasks中的任务执行完成后，若希望在基础上触发其他的任务，这时就需要定义handlers。例如，当通过ansible的模块对目标主机的配置文件进行修改之后，如果任务执行成功，可以触发一个触发器，在触发器中定义目标主机的服务重启操作，以使配置文件生效，handlers触发器具有以下优点。
1.handlers是Ansible提供的条件机制之一，handlers和task很类似，但是他在被task通知的时候才会触发执行
2.handlers只会在所有任务执行完成后执行，而且即使被通知了多次，它也只会执行一次，handlers按照定义的顺序依次执行

### **3. 角色**

将多种不同的tasks的文件集中存储在某个目录下，则该目录就是角色，角色一般存放在/etc/ansible/roles/目录中，可通过ansible的配置文件来调整默认的角色目录。/etc/ansible/roles目录下有很多的子目录，其中每一个子目录对应一个角色。每个角色也有自己的目录结构。

![](https://pic.imgdb.cn/item/6501789f661c6c8e5475d425.jpg)


每个角色的定义，以特定的层级目录结构进行组织，以Mariadb（mysql角色) 为例

1.files：存放copy或script等模块调用的文件

2.templates：存放template模块查找所需要的模板文件的目录，如mysql配置文件等模板

3.tasks：任务存放目录

4.handlers：存放相关触发执行器的目录

5.vars：变量存放的目录

6.meta：用于存放此角色元数据

7.default：默认变量存放目录，文件中定义了此角色使用的默认变量


### **4. 变量**


实例1: 利用系统变量获取主机系统
```
  tasks:
    - name: Gather system information
      setup:

    - name: Print ansible_distribution
      debug:
        var: ansible_distribution
```
  


### **5. Template模板**

配置文件如果使用copy模块去下发的话，那么所有主机的配置都是一样的； 如果下发的配置文件里有可变的配置，需要用到template模块。

5.1 利用template模块下发可变的配置文件

```
[root@ansible ~]# cat /tmp/test
my name is {{ myname }} # 自定义变量
my name is {{ ansible_all_ipv4_addresses[1] }}  # 系统变量
```


```
[root@ansible ~]# cat /etc/ansible/filevars.yml
---
- hosts: all
  gather_facts: True    #开启系统变量
  vars:
  - myname: "cloud" #自定义变量
  tasks:
  - name: template test
    template: src=/tmp/test dest=/root/test #使用template下发可变配置文件
...
[root@ansible ~]# ansible-playbook /etc/ansible/filevars.yml

PLAY [all] ************************************************************************

TASK [Gathering Facts] ************************************************************
ok: [192.168.200.112]
ok: [192.168.200.113]

TASK [template test] **************************************************************
changed: [192.168.200.113]
changed: [192.168.200.112]

PLAY RECAP ************************************************************************
192.168.200.112            : ok=2    changed=1    unreachable=0    failed=0   
192.168.200.113            : ok=2    changed=1    unreachable=0    failed=0  

[root@client1 ~]# cat /tmp/test 
ip 192.168.122.1 cpu 1
time 2019-05-15
```

5.2 下发配置文件里面使用判断语法

```
[root@ansible ~]# vim /tmp/if.j2
{% if PORT %}       #if PORT存在
ip=0.0.0.0:{{ PORT }}
{% else %}          #否则的话
ip=0.0.0.0:80
{% endif %}         #结尾
[root@ansible ~]# vim /etc/ansible/test_ifvars.yml
---
- hosts: all
  gather_facts: True    #开启系统内置变量
  vars:
  - PORT: 90        #自定义变量
  tasks:
  - name: jinja2 if test
    template: src=/tmp/if.j2 dest=/root/test
...
[root@ansible ~]# ansible-playbook /etc/ansible/test_ifvars.yml

PLAY [all] ************************************************************************

TASK [Gathering Facts] ************************************************************
ok: [192.168.200.112]
ok: [192.168.200.113]

TASK [jinja2 if test] *************************************************************
changed: [192.168.200.112]
changed: [192.168.200.113]

PLAY RECAP ************************************************************************
192.168.200.112            : ok=2    changed=1    unreachable=0    failed=0   
192.168.200.113            : ok=2    changed=1    unreachable=0    failed=0  

[root@client1 ~]# cat /root/test 
       #if PORT存在
ip=0.0.0.0:90
         #结尾
```



以下是你给出的命令和输出的Markdown格式：

```markdown
1. 将变量PORT值设为空，然后运行Ansible playbook：

```shell
[root@ansible ~]# vim /etc/ansible/test_ifvars.yml
---
- hosts: all
  gather_facts: True    #开启系统内置变量
  vars:
  - PORT:         #变量为空
  tasks:
  - name: jinja2 if test
    template: src=/tmp/if.j2 dest=/root/test
...
[root@ansible ~]# ansible-playbook /etc/ansible/test_ifvars.yml
```

运行结果：

```shell
PLAY [all] ************************************************************************

TASK [Gathering Facts] ************************************************************
ok: [192.168.200.112]
ok: [192.168.200.113]

TASK [jinja2 if test] *************************************************************
changed: [192.168.200.112]
changed: [192.168.200.113]

PLAY RECAP ************************************************************************
192.168.200.112            : ok=2    changed=1    unreachable=0    failed=0   
192.168.200.113            : ok=2    changed=1    unreachable=0    failed=0
```

在客户端检查生成的文件：

```shell
[root@client1 ~]# cat /root/test 
          #否则的话
ip=0.0.0.0:80
         #结尾
```

2. 使用Ansible playbook下发可执行动作的可变的nginx配置文件：

```shell
[root@ansible ~]# cp nginx.conf /tmp/nginx.j2
[root@ansible ~]# head -3 /tmp/nginx.j2
#user  nobody;
worker_processes  {{ ansible_processor_vcpus }};	#可变的参数
```

创建并运行Ansible playbook：

```shell
[root@ansible ~]# cat /etc/ansible/test_nginxvars.yml
---
- hosts: all
  gather_facts: True    #开启系统内置变量
  tasks:
  - name: nginx conf
    template: src=/tmp/nginx.j2 dest=/usr/local/nginx/conf/nginx.conf
    notify:
    - reload nginx  #下发通知给handlers模块执行名字叫做reload nginx的动作
  handlers: #定义动作
  - name: reload nginx  #动作的名字
    shell: /usr/local/nginx/sbin/nginx -s reload
...
[root@ansible ~]# ansible-playbook /etc/ansible/test_nginxvars.yml
```

运行结果：

```shell
PLAY [all] ************************************************************************

TASK [Gathering Facts] ************************************************************
ok: [192.168.200.113]
ok: [192.168.200.112]

TASK [nginx conf] *****************************************************************
ok: [192.168.200.112]
ok: [192.168.200.113]

PLAY RECAP ************************************************************************
192.168.200.112            : ok=2    changed=0    unreachable=0    failed=0   
192.168.200.113            : ok=2    changed=0    unreachable=0    failed=0  
```

在客户端检查生成的配置文件：

```shell
[root@client1 ~]# head -3 /usr/local/nginx/conf/nginx.conf
#user  nobody;
worker_processes  1;
```

#### **5.1 模版变量获取**

方式一：

```
{% for host in groups['k8s_masters'] %}
    server {{ host }} {{ hostvars[host]['ansible_default_ipv4']['address'] }}:6443 check
{% endfor %}
```

方式二：
```
如果你想在生成的 HAProxy 配置文件中使用主机的 IP 地址代替主机名，你可以修改你的模板，如下所示：

{% for host in groups['k8s_master'] %}
    server {{ hostvars[host]['ansible_default_ipv4']['address'] }} {{ hostvars[host]['ansible_default_ipv4']['address'] }}:6443 check
{% endfor %}
在这个修改后的模板中，我们使用了 hostvars[host]['ansible_default_ipv4']['address'] 来获取每个主机的 IP 地址，并用这个 IP 地址代替了原来的主机名。

请注意，这个修改假设你的主机都有一个定义了 'ansible_default_ipv4' 变量的 IPv4 地址。这个变量通常由 Ansible 的 setup 模块自动收集，但如果你的主机没有 IPv4 地址，或者没有运行 setup 模块，你可能需要手动设置这个变量。
```