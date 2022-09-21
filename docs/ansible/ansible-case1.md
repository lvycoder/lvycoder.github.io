# **Ansible 案例**

!!! info "准备工作"
    - 配置inventory/pve


```shell
[pve]
master.pve hostname=master ansible_host=192.168.1.11 ansible_ssh_user=root ansible_ssh_pass="pass@word1"
```



### **案例**



```yaml
- hosts: pve
  gather_facts: no  # 关闭收集系统信息
  tasks:
    - name: ping
      ping: 
    - name: wall
      shell: wall hello
- hosts: pve
  gather_facts: no
  tasks:
    - name: install httpd 
      yum: name=httpd update_cache=yes
    - name: start service
      service: name=httpd state=started enabled=yes 
```

### **Ansible 常用选项:**

  - -C  //预执行
  - --list-hosts //列出正在运行任务的主机
  - --list-tasks //列出tasks
  - --limit 主机列表 //只针对特定主机执行 




#### **案例一：create_user.yaml**
!!! info "Ansible 批量创建用户"
    - 这里设置password需要使用python命令生成sha-512算法,pw是要加密的密码
    ```
    a=$(python3 -c 'import crypt,getpass;pw="123456";print(crypt.crypt(pw))')
    $ echo $a
    QUbhMQ9BAGQBE
    ```

##### **示例一:（用户密码）**
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

##### **示例二:（公钥形式）**
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

### **Ansible Roles 目录编排**


#### **Roles各个目录的作用**

- file 存放有copy和script等调用
- templates 模版
- task      任务
- handler   触发器
- vars      定义变量
- mete
- default 设定变量时使用此目录中的main.yaml,比vars的优先级低



playbook 调用角色：
```yaml
- hosts: pve
  remote_user: root
  roles:
    - mysql 
```

执行
```
ansible-playbook  -i inventory/pve  pve.yaml
```