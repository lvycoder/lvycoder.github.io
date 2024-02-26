  
## **更换国内源**

通常来说，我们在安装好系统之后需要对yum/apt的源进行更换，默认为国外源比较慢～

!!! info "ubuntu22.04 清华源"
    - 需要注意一下，如果 apt update 报错，就将https改成http
    - 如果需要添加其他的版本的源可以访问: https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
    ```
    # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
    deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
    deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
    deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

    deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
    # deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

    # 预发布软件源，不建议启用
    # deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
    # # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
    ```

## **清华源地址**

- https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/