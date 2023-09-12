
## **YAML 介绍**

YAML 是一种用来表达资料序列的格式，参考了其他多种语言所以具有很高的可 读性。YAML 是 YAML Ain’t Markup Language 的缩写，即 YAML 不是 XML。不过在 研发这种语言时，YAML 的意思其实是”Yet Another Markup Language”（仍是一种标 记语言）。其特性如下：

- 具有很好的可读性，易于实现；
- 表达能力强，扩展性好；
- 和脚本语言的交互性好；
- 有一个一致的信息模型； 
- 可以基于流来处理。


### **YAML 语法**

YAML 的语法和其它语言类似，也可以表达散列表、标量等数据结构。其中结构 （structure）通过空格来展示；序列（sequence）里的项用”-”来代表；Map 里的键值 对用”:”分隔。YAML 文件扩展名通常为：yaml，如：example.yaml。下面是 YAML 的一个示例。


### **YAML常用的数据类型**

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

### ** Inventory(主机清单)**

Inventory 文件中以中括号中的字符标识为组名，将主机分组管理，也可以将同一主机同时划分到多个不同的组中。如果被管理主机使用非默认的SSH端口，以下例子主要分了两个主机组cka-1和cka-2，inventory 下有很多的主机文件，注意这里ansible的配置文件是做了修改的。

```yaml
$ cat inventory/cka
[cka-1]
cka.master hostname=master0 ansible_host=172.30.42.244 ansible_user=lixie

[cka-2]
cka.node1  hostname=node1 ansible_host=172.30.192.106 ansible_user=lixie
cka.node2  hostname=node2 ansible_host=172.30.226.223 ansible_user=lixie

```

### **Inventory 参数: **

Ansible 基于 SSH 连接 Inventory 中指定的被管理主机时，还可以通过参数指定 交互方式，这些参数如表 3-2 所示。

| 参数 | 含义 |
| --- | --- |
| ansible_ssh_port | 指定 SSH 连接的端口号 |
| ansible_ssh_user | 指定 SSH 连接的用户名 |
| ansible_ssh_pass | 指定 SSH 连接的密码 |
| ansible_sudo_pass | 指定执行 sudo 命令时的密码 |
| ansible_connection | 定义 SSH 连接的类型（例如：local, ssh, paramiko） |
| ansible_ssh_private_key_file | 指定 SSH 连接的私钥文件路径 |
| ansible_shell_type | 指定主机所使用的 Shell 解释器，默认是 sh |
| ansible_python_interpreter | 指定 Python 解释器的路径 |
| ansible_*_interpreter | 指定主机上其他语法解释器的路径 |