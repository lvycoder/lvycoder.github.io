
# Docker 基本管理


随着计算机近几十年的蓬勃发展，产生了大量优秀系统和软件。软件开发人员可以自由选择各 种软件应用。但同时带来的问题就是需要维护一个非常庞大的开发、测试和生产环境。 面对这种 情况，Docker 容器技术横空出世，提供了简单、灵活、高效的解决方案，不需要过多地改变现有 的使用习惯，就可以和已有的工具，如 OpenStack 等配合使用。因此，掌握 Docker 相关技术也是 途经云计算的必经之路。

本章将依次介绍 Docker 的三大核心概念——镜像、容器、仓库，以及安装 Docker 与介绍围 绕镜像和容器的具体操作。
![](https://pic1.imgdb.cn/item/6347711c16f2c2beb1e5a99a.jpg)



## **1.1 Docker 概述**

因为 Docker 轻便、快速的特性，可以使应用达到快速迭代的目的。每次小的变更，马上就可 以看到效果，而不用将若干个小变更积攒到一定程度再变更。每次变更一小部分其实是一种非常安 全的方式，在开发环境中能够快速提高工作效率。


Docker 容器能够帮助开发人员、系统管理员、质量管理和版本控制工程师在一个生产环节中 一起协同工作。制定一套容器标准能够使系统管理员更改容器的时候，程序员不需要关心容器的变 化，而更专注自己的应用程序代码。从而隔离开了开发和管理，简化了开发和部署的成本。


### **1.1.1 什么是 Docker**

如果要方便的创建运行在云平台上的应用，必须要脱离底层的硬件，同时还需要任何时 间地 点可获取这些资源，这正是 Docker 所能提供的。Docker 的容器技术可以在一台主机上轻松为任何 应用创建一个轻量级的、可移植的、自给自足的容器。通过这种容器打包应用程序，意味着简化了 重新部署、调试这些琐碎的重复工作，极大的提高了工作效率。


### **1.1.2 Docker 的优势**

Docker 容器运行速度很快，启动和停止可以在秒级实现，比传统虚拟机要快很多；Docker 核 心解决的问题是利用容器来实现类似虚拟机的功能，从而利用更加节省的硬件资源提供给用户更多 的计算资源。因此，Docker 容器除了运行其中的应用之外，基本不消耗额外的系统资源，在保证 应用性能的同时，又减小了系统开销，使得一台主机上同时运行数千个 Docker 容器成为可能。 Docker 操作方便，可以通过 Dockerfile 配置文件支持灵活的自动化创建和部署。表 1-1 将 Docker 容器技术与传统虚拟机的特性进行了比较。


!!! warning "个人理解: 虚拟机和容器的同个时代的不同产物"

表1-1 Docker 容器与传统虚拟机的区别

![](https://pic1.imgdb.cn/item/63477aac16f2c2beb1f2f424.jpg)

Docker 之所以拥有众多优势，与操作系统虚拟化自身的特点是分不开的。传统虚拟机需要有 额外的虚拟机管理程序和虚拟机操作系统层，而 Docker 容器则是直接在操作系统层面之上实现的 虚拟化。图 1.2 是 Docker 与传统虚拟机架构。

![](https://pic1.imgdb.cn/item/634776ba16f2c2beb1ed6983.jpg)


### **1.1.3 镜像**

镜像、容器、仓库是 Docker 的三大核心概念。其中 Docker 的镜像是创建容器的基础，类似虚拟机的快照,可以理解为一个面向 Docker 容器引擎的只读模板。例如：一个镜像可以是一个完整 的 Cent OS 操作系统环境，称为一个 CentOS 镜像；也可以是一个安装了 MySQL 的应用程序，称之为一个 MySQL 镜像等等。

所有的容器都是基于镜像来实现的～，所以image 就显得很重要！！！

### **1.1.4 容器**

Docker 的容器是从镜像创建的运行实例，它可以被启动、停止和删除。所创建的每一个容器 都是相互隔离、互不可见，以保证安全性的平台。可以将容器看作是一个简易版的 Linux 环境， Docker 利用容器来运行和隔离应用。


### **1.1.5 仓库**

有了镜像，当然需要有存放他的地方，Docker 仓库就是用来集中保存镜像的地方，当创建了自己的镜像之后，可以使用 push 命令将它 上传到公有仓库（Public）或者私有仓库（Private）。当下次要在另外一台机器上使用这个镜像 时，只需从仓库获取。

常见的镜像仓库:

- 阿里云镜像仓库
- Ucloud 镜像仓库
- Harbor 镜像仓库
- docker hub (官方库)

仓库注册服务器（Registry）是存放仓库的地方，其中包含了多个仓库。每个仓库集中存放某 一类镜像，并且使用不同的标签（tag）来区分它们。目前最大的公共仓库是 docker Hub，存放了 数量庞大的镜像供用户下载使用。

---


## **1.2 安装 Docker**

这里主要介绍常见的几种，YUM针对于Centos系统，APT针对于ubuntu系统，脚本式快捷安装。

**支持的平台:**

Docker Engine 可通过 Docker Desktop 在各种Linux 平台、 macOS和Windows 10 上使用，并且可以作为静态二进制安装使用。在下方找到您首选的操作系统。

![](https://pic1.imgdb.cn/item/63477bbb16f2c2beb1f48e67.jpg)

![](https://pic1.imgdb.cn/item/63477c1f16f2c2beb1f521b3.jpg)


!!! Warning "温馨提示"
    这里面之前遇到一个坑，原因就是因为我们使用的Mac办公，ubuntu需要拉不来镜像，需要Mac拉好上传上去，结果Mac拉的版本是amd架构的～

    - 解决方法: k8s.gcr.io/nfd/node-feature-discovery:v0.11.0 <font color=red>--platform linux/amd64</font>

官网: https://docs.docker.com/engine/install/

### **1.2.1 Apt 方式安装:**

移除旧docker包
```shell
 sudo apt-get remove docker docker-engine docker.io containerd runc
```


设置存储库

- 更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库：

```shell
 sudo apt-get update
 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

- 添加 Docker 的官方 GPG 密钥：


```shell
 sudo mkdir -p /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

- 使用以下命令设置存储库：

```shell
 echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

```

安装docker

```shell
 sudo apt-get update
 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```




### **1.2.2 YUM 方式安装:**

移除旧docker包
```shell
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

配置YUM源

```shell
sudo yum install -y yum-utils
sudo yum-config-manager \
--add-repo \
http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo 
```


安装docker-ce

```shell
sudo yum install -y docker-ce docker-ce-cli containerd.io


#以下是在安装k8s的时候使用
yum install -y docker-ce-20.10.7 docker-ce-cli-20.10.7  containerd.io-1.4.6
```

启动

```shell
systemctl enable docker --now
```


配置加速

```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://82m9ar63.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```




### **1.2.3 脚本式安装**

官方提供:
```shell
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

rancher提供:
```shell
curl https://releases.rancher.com/install-docker/19.03.sh | sh
```



--- 
安装好的 Docker 系统有两个程序，Docker 服务端和 Docker 客户端。其中 Docker 服务端是 一个服务进程，负责管理所有容器。Docker 客户端则扮演着 Docker 服务端的远程控制器，可以用 来控制 Docker 的服务端进程。大部分情况下 Docker 服务端和客户端运行在一台机器上。




## **1.3 Docker 镜像操作**


运行 Docker 容器前需要本地存在对应的镜像。如果不存在本地镜像，Docker 就会尝试从默认 镜像仓库下载。镜像仓库是由 Docker 官方维护的一个公共仓库，可以满足用户的绝大部分需求。 用户也可以通过配置来使用自定义的镜像仓库。

**帮助命令:**
```shell
[ucloud] root@master0:~# docker --help

Usage:  docker [OPTIONS] COMMAND

A self-sufficient runtime for containers

Options:
      --config string      Location of client config files (default "/root/.docker")
  -c, --context string     Name of the context to use to connect to the daemon (overrides DOCKER_HOST env var and default context set with "docker context use")
  -D, --debug              Enable debug mode
  -H, --host list          Daemon socket(s) to connect to
  -l, --log-level string   Set the logging level ("debug"|"info"|"warn"|"error"|"fatal") (default "info")
      --tls                Use TLS; implied by --tlsverify
      --tlscacert string   Trust certs signed only by this CA (default "/root/.docker/ca.pem")
      --tlscert string     Path to TLS certificate file (default "/root/.docker/cert.pem")
      --tlskey string      Path to TLS key file (default "/root/.docker/key.pem")
      --tlsverify          Use TLS and verify the remote
  -v, --version            Print version information and quit
```

管理CLI:
```shell
[ucloud] root@master0:~# docker search nginx
NAME                                              DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
nginx                                             Official build of Nginx.                        17448     [OK]
```

执行 docker search lamp 命令后，返回很多包含 lamp 关键字的镜像，其中返回信息包括镜像 名称（NAME）、描述（DESCRIPTION）、星级（STARS）、是否官方创建（OFFICIAL）、是 否主动创建（AUTOMATED）。默认的输出结果会按照星级评价进行排序，表示该镜像受欢迎程 度。在下载镜像时，可以参考星级。在搜索时，还可以使用-s 或者--stars=x 显示指定星级以上的镜 像，星级越高表示越受欢迎；是否官方创建是指是否是由官方项目组创建和维护的镜像，一般官方项目组维护的镜像使用单个单词作为镜像名称，称为基础镜像或者根镜像。像 reinblau/lamp 这种 命名方式的镜像，表示是由 docker Hub 的用户 reinblau 创建并维护的镜像，带有用户名为前缀； 是否主动创建是指是否允许用户验证镜像的来源和内容。


```shell
docker pull image-name   //获取镜像
docker push image-name   //推送镜像
docker images            //查看镜像
docker rm -f image-name   //强制删除镜像
docker images -aq        //查看所有镜像ID
docker save -o 存储文件名  存储的镜像名  //保存镜像
docker load < 存储文件名   //导入镜像
```

对于 Docker 镜像来说，如果下载镜像时不指定标签，则默认会下载仓库中最新版本的镜 像，即选择标签为 latest 标签，也可通过指定的标签来下载特定版本的某一镜像。这里标签 （tag）就是用来区分镜像版本的。


!!! warning "温馨提示"
    - 在登陆ucloud的镜像仓库，需要将密码用''引起来，例如:
    - docker login -u user-name -p 'password' uhub.service.ucloud.cn




## **1.4 Docker 容器操作**
容器是 Docker 的另一个核心概念。简单说，容器是镜像的一个运行实例，是独立运行的一个 或一组应用以及它们所必需的运行环境，包括文件系统、系统类库、shell 环境等。镜像是只读模 板，而容器会给这个只读模板添加一个额外的可写层。


管理CLI:
```shell
docker stop 容器名称/容器ID
docker start  容器名称/容器ID
docker restart 容器名称/容器ID
docker ps -aq  查看所有容器ID
docker export 容器ID/名称 > 文件名  //容器导出
cat 文件名 | docker import - 生成的镜像名称:标签  //容器导入
```


## **1.5 Docker 镜像管理**

Docker 镜像除了是 Docker 的核心技术之外，也是应用发布的标准格式。一个完整的 Docker 镜像可以支撑一个 Docker 容器的运行，在 Docker 的整个使用过程中，进入一个已经定型的容器之后，就可以在容器中进行操作，最常见的操作就是在容器中安装应用服务。 如果要把已经安装的服务进行迁移，就需要把环境以及搭建的服务生成新的镜像。本案例将介绍 如何创建 Docker 镜像。


### **1.5.1 Docker镜像结构**

镜像不是一个单一的文件，而是有多层构成。可以通过 docker history 命令查看镜像中各 层内容及大小，每层对应着 Dockerfile 中的一条指令。Docker 镜像默认存储在 /var/lib/docker/<storage-driver>目录中。容器其实是在镜像的最上面加了一层读写层， 在运 行容器里做的任何文件改动，都会写到这个读写层。如果删除了容器，也就删除了其最上面的 读写层，文件改动也就丢失了。Docker 使用存储驱动管理镜像每层内容及可读写层的容器 层。Docker 镜像是分层的，下面这些知识点非常重要。

- （1）Dockerfile 中的每个指令都会创建一个新的镜像层；

- （2）镜像层将被缓存和复用；

- （3） 当Dockerfile 的指令修改了，复制的文件变化了，或者构建镜像时指定的变量不同 了，对应的镜像层缓存就会失效；

- （4）某一层的镜像缓存失效，它之后的镜像层缓存都会失效；

- （5）镜像层是不可变的，如果在某一层中添加一个文件，然后在下一层中删除它，则镜 像中依然会包含该文件，只是这个文件在 Docker 容器中不可见了。


### **1.5.2 Dockerfile介绍**

Dockfile 是一种被 Docker 程序解释的脚本，Dockerfile 由多条的指令组成，每条指令对 应Linux 下面的一条命令。Docker 程序将这些Dockerfile 指令翻译成真正的Linux 命令。 Dockerfile 有自己书写格式和支持的命令，Docker 程序解决这些命令间的依赖关系，类似于 Makefile。Docker 程序将读取 Dockerfile，根据指令生成定制的镜像。相比镜像这种黑盒子， Dockerfile 这种显而易见的脚本更容易被使用者接受，它明确的表明镜像是怎么产生的。有了 Dockerfile，当有定制额外的需求时，只需在 Dockerfile 上添加或者修改指令， 重新生成镜像。












### **附件:**



