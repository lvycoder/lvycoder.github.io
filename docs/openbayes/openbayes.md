# **Openbayes 运维管理**


## **Openbayes安装文档**

完成整个openbayes大致可以分为以下四个步骤

!!! info "步骤一  环境初始化"
    - 系统时区
    - 网络配置：apt源，hosts配置
    - docker环境，gpu驱动，kubeadm 环境
    - 以上可以使用Ansible自动化实现
    - 其实就是做系统初始化和准备一个k8s环境，那么第一步准备工作就完成了。
    ```
    git clone https://github.com/signcl/ansible-kubernetes.git
    ansible-playbook -i inventory/pve pve.yaml
    ```


!!! warning "温馨提示"
    - 初始化k8s集群后，注意要给所在的gpu服务器打label，一般情况通常就是安装gpu显卡类型来区分
    - 两个label 分别为: (以A100举例)
    ```shell
    k label node a100-1  node-role.kubernetes.io/gpu=
    k label node a100-1  node-role.kubernetes.io/user=
    ```
    - 在 node-feature-discovery namespace下会起来两个pod，gpu-feature-discovery和nfd-worker
    - 一般情况如果是新加的机器可能会出现gpu-feature-discovery和nfd-worker起不来的情况，这时需要重启该机器
    - 在ubuntu22.04 中，会出现bird这个bgp软件无法直接使用apt安装，需要手动安装一下 aptitude，在用 aptitude 安装bird
    - 在ubuntu22.04 默认只开启cgroup v2从而导致lxcfs不生效情况
    - 以及可能会出现，pod地址无法ping通其他机器的情况，在openbayes produce 升级这篇有详细说明。




!!! info "步骤二 外置环境要求"
    - Mysql数据库
        - 数据库可以参考数据库中Mysql-operator这篇文章
    - rook-ceph存储服务
        - rook-ceph的csi驱动镜像默认是外网进行拉取的，所以要修改。
        - 磁盘是否设置自动识别
        - 最重要的是openbayes依赖的rbd和cephfs,需要有这两个sc
        - 还需要创建好一个cephfs的pvc
        ```shell
        vi ceph-pvc.yaml

        apiVersion: v1
        kind: PersistentVolumeClaim
        metadata:
        name: cephfs-pvc
        namespace: default
        spec:
        accessModes:
        - ReadWriteMany
        resources:
            requests:
            storage: 50Gi    //这个是根据具体而定
        storageClassName: rook-cephfs
        ```
    - traefik （ingress controller）
        - treafik 可以参考Helm中的文章



!!! info "步骤三 Openbayes 安装"
    - Helm 安装
    ```
    helm repo add openbayes https://dev.openbayes.com/charts --username openbayes --password rTHbzE7p6eO
    helm repo update
    helm repo list
    helm upgrade --install openbayes openbayes/openbayes -f ./openbayes-values.yaml   //在rancher-gitops这个仓库可以找到values文件
    ```


!!! info "步骤四 其他依赖服务"
    - prometheus 监控






Openbayes 各服务对应关系

| Openbayes服务      | 作用                         |
| ----------- | ------------------------------------ |
| openbayes-clash       | 外网代理  |
| openbayes-console       | 前端 |
| openbayes-archive-service  |  |
| openbayes-docs  | 首页和文档|
| openbayes-command-runner | k8s 和API信息同步|
| openbayes-gear-controller | 模型训练|
| openbayes-serving-controller | 模型部署 |
| openbayes-minio-server | 数据集 |
| openbayes-daemon-server | openbayes后台进程 |
| openbayes-storage-server | 存储服务 |


       


