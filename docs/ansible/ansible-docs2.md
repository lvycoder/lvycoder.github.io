
## **YAML 介绍**

YAML 是一种用来表达资料序列的格式，参考了其他多种语言所以具有很高的可 读性。YAML 是 YAML Ain’t Markup Language 的缩写，即 YAML 不是 XML。不过在 研发这种语言时，YAML 的意思其实是”Yet Another Markup Language”（仍是一种标 记语言）。其特性如下：

- 具有很好的可读性，易于实现；
- 表达能力强，扩展性好；
- 和脚本语言的交互性好；
- 有一个一致的信息模型； 
- 可以基于流来处理。


## **YAML 语法**

YAML 的语法和其它语言类似，也可以表达散列表、标量等数据结构。其中结构 （structure）通过空格来展示；序列（sequence）里的项用”-”来代表；Map 里的键值 对用”:”分隔。YAML 文件扩展名通常为：yaml，如：example.yaml。下面是 YAML 的一个示例。


## **YAML常用的数据类型**

YAML 中有两种常用的数据类型：list 和 dictionary。

1.list （列表）

列表（list）的所有元素均使用”-”开头，例如：

```shell
-Apple 
-Orange 
-Strawberry 
-Mango

```

2.dictionary

字典（dictionary）通过 key 与 value 进行标识，例如：

```shell
name: Example Developer
Job: Developer
Skill: Elite
```


也可以使用 key:value 的形式放置于{ }中进行表示，例如：
```
{ name: Example Developer, Job: Developer, Skill: Elite}
```

---


## **Ansible 基础元素介绍**

### **1. Inventory(主机清单)**

Inventory 文件中以中括号中的字符标识为组名，将主机分组管理，也可以将同一主机同时划分到多个不同的组中。如果被管理主机使用非默认的SSH端口，以下例子主要分了两个主机组cka-1和cka-2，inventory 下有很多的主机文件，注意这里ansible的配置文件是做了修改的。

```yaml
$ cat inventory/cka
[cka-1]
cka.master hostname=master0 ansible_host=172.30.42.244 ansible_user=lixie

[cka-2]
cka.node1  hostname=node1 ansible_host=172.30.192.106 ansible_user=lixie
cka.node2  hostname=node2 ansible_host=172.30.226.223 ansible_user=lixie

```

#### **Inventory 参数: **

Ansible 基于 SSH 连接 Inventory 中指定的被管理主机时，还可以通过参数指定 交互方式，这些参数如表 3-2 所示。

```shell
ansible_ssh_host
      将要连接的远程主机名.与你想要设定的主机的别名不同的话,可通过此变量设置.

ansible_ssh_port
      ssh端口号.如果不是默认的端口号,通过此变量设置.

ansible_ssh_user
      默认的 ssh 用户名

ansible_ssh_pass
      ssh 密码(这种方式并不安全,我们强烈建议使用 --ask-pass 或 SSH 密钥)

ansible_sudo_pass
      sudo 密码(这种方式并不安全,我们强烈建议使用 --ask-sudo-pass)

ansible_sudo_exe (new in version 1.8)
      sudo 命令路径(适用于1.8及以上版本)

ansible_connection
      与主机的连接类型.比如:local, ssh 或者 paramiko. Ansible 1.2 以前默认使用 paramiko.1.2 以后默认使用 'smart','smart' 方式会根据是否支持 ControlPersist, 来判断'ssh' 方式是否可行.

ansible_ssh_private_key_file
      ssh 使用的私钥文件.适用于有多个密钥,而你不想使用 SSH 代理的情况.

ansible_shell_type
      目标系统的shell类型.默认情况下,命令的执行使用 'sh' 语法,可设置为 'csh' 或 'fish'.

ansible_python_interpreter
      目标主机的 python 路径.适用于的情况: 系统中有多个 Python, 或者命令路径不是"/usr/bin/python",比如  \*BSD, 或者 /usr/bin/python
      不是 2.X 版本的 Python.我们不使用 "/usr/bin/env" 机制,因为这要求远程用户的路径设置正确,且要求 "python" 可执行程序名不可为 python以外的名字(实际有可能名为python26).

      与 ansible_python_interpreter 的工作方式相同,可设定如 ruby 或 perl 的路径....
```