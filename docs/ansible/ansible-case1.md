# **Ansible 案例**

!!! info "准备工作"
    - 配置inventory/pve
    ```shell
    [pve]
    master.pve hostname=master ansible_host=192.168.1.11 ansible_ssh_user=root ansible_ssh_pass="pass@word1"
    ```
!!! warning "温馨提示"
    - 可能出现sudo权限不够的问题，那么可以在inventory添加以下内容
    ```shell
    gtx3090.c1 hostname=ubuntu ansible_ssh_user=xxx ansible_sudo_pass=xxx ansible_ssh_pass="password"
    ```

!!! error "ubuntu22.04 执行报错"
    ```shell
    TASK [Gathering Facts] *******************************************************************************************************
    fatal: [axis]: FAILED! => {"ansible_facts": {}, "changed": false, "failed_modules": {"ansible.legacy.setup": {"failed": true, "module_stderr": "/bin/sh: 1: /usr/bin/python: not found\n", "module_stdout": "", "msg": "The module failed to execute correctly, you probably need to set the interpreter.\nSee stdout/stderr for the exact error", "rc": 127}}, "msg": "The following modules failed to execute: ansible.legacy.setup\n"}
    ```



!!! info "Ansible 常用选项"
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