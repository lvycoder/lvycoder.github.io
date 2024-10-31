# 实战 Tekton 流水线

[ ](https://github.com/cnych/qikqiak.com/edit/master/docs/devops/tekton/action.md "编辑此页")

# 实战 Tekton 流水线

前面我们讲解了使用 Jenkins 流水线来实现 Kubernetes 应用的 CI/CD，现在我们来将这个流水线迁移到 Tekton 上面来，其实整体思路都是一样的，就是把要整个工作流划分成不同的任务来执行，前面工作流的阶段划分了以下几个阶段：`Clone 代码 -> 单元测试 -> Golang 编译打包 -> Docker 镜像构建/推送 -> Kubectl/Helm 部署服务`。

在 Tekton 中我们就可以将这些阶段直接转换成 Task 任务，Clone 代码在 Tekton 中不需要我们主动定义一个任务，只需要在执行的任务上面指定一个输入的代码资源即可。下面我们就来将上面的工作流一步一步来转换成 Tekton 流水线，代码仓库同样还是 `http://git.k8s.local/course/devops-demo.git`。

## Clone 代码

虽然我们可以不用单独定义一个 Clone 代码的任务，直接使用 git 类型的输入资源即可，由于这里涉及到的任务较多，而且很多时候都需要先 Clone 代码然后再进行操作，所以最好的方式是将代码 Clone 下来过后通过 Workspace 共享给其他任务，这里我们可以直接使用 Catalog [git-clone](https://hub.tekton.dev/tekton/task/git-clone) 来实现这个任务，我们可以根据自己的需求做一些定制，对应的 Task 如下所示：
    
    
    # task-clone.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: git-clone
      labels:
        app.kubernetes.io/version: "0.8"
      annotations:
        tekton.dev/pipelines.minVersion: "0.29.0"
        tekton.dev/categories: Git
        tekton.dev/tags: git
        tekton.dev/displayName: "git clone"
        tekton.dev/platforms: "linux/amd64,linux/s390x,linux/ppc64le,linux/arm64"
    spec:
      description: >-
        These Tasks are Git tasks to work with repositories used by other tasks
        in your Pipeline.
    
        The git-clone Task will clone a repo from the provided url into the
        output Workspace. By default the repo will be cloned into the root of
        your Workspace. You can clone into a subdirectory by setting this Task's
        subdirectory param. This Task also supports sparse checkouts. To perform
        a sparse checkout, pass a list of comma separated directory patterns to
        this Task's sparseCheckoutDirectories param.
      workspaces:
        - name: output
          description: The git repo will be cloned onto the volume backing this Workspace.
        - name: ssh-directory
          optional: true
          description: |
            A .ssh directory with private key, known_hosts, config, etc. Copied to
            the user's home before git commands are executed. Used to authenticate
            with the git remote when performing the clone. Binding a Secret to this
            Workspace is strongly recommended over other volume types.
        - name: basic-auth
          optional: true
          description: |
            A Workspace containing a .gitconfig and .git-credentials file. These
            will be copied to the user's home before any git commands are run. Any
            other files in this Workspace are ignored. It is strongly recommended
            to use ssh-directory over basic-auth whenever possible and to bind a
            Secret to this Workspace over other volume types.
        - name: ssl-ca-directory
          optional: true
          description: |
            A workspace containing CA certificates, this will be used by Git to
            verify the peer with when fetching or pushing over HTTPS.
      params:
        - name: url
          description: Repository URL to clone from.
          type: string
        - name: revision
          description: Revision to checkout. (branch, tag, sha, ref, etc...)
          type: string
          default: ""
        - name: refspec
          description: Refspec to fetch before checking out revision.
          default: ""
        - name: submodules
          description: Initialize and fetch git submodules.
          type: string
          default: "true"
        - name: depth
          description: Perform a shallow clone, fetching only the most recent N commits.
          type: string
          default: "1"
        - name: sslVerify
          description: Set the `http.sslVerify` global git config. Setting this to `false` is not advised unless you are sure that you trust your git remote.
          type: string
          default: "true"
        - name: crtFileName
          description: file name of mounted crt using ssl-ca-directory workspace. default value is ca-bundle.crt.
          type: string
          default: "ca-bundle.crt"
        - name: subdirectory
          description: Subdirectory inside the `output` Workspace to clone the repo into.
          type: string
          default: ""
        - name: sparseCheckoutDirectories
          description: Define the directory patterns to match or exclude when performing a sparse checkout.
          type: string
          default: ""
        - name: deleteExisting
          description: Clean out the contents of the destination directory if it already exists before cloning.
          type: string
          default: "true"
        - name: httpProxy
          description: HTTP proxy server for non-SSL requests.
          type: string
          default: ""
        - name: httpsProxy
          description: HTTPS proxy server for SSL requests.
          type: string
          default: ""
        - name: noProxy
          description: Opt out of proxying HTTP/HTTPS requests.
          type: string
          default: ""
        - name: verbose
          description: Log the commands that are executed during `git-clone`'s operation.
          type: string
          default: "true"
        - name: gitInitImage
          description: The image providing the git-init binary that this Task runs.
          type: string
          default: "cnych/tekton-git-init:v0.29.0"
        - name: userHome
          description: |
            Absolute path to the user's home directory.
          type: string
          default: "/home/nonroot"
      results:
        - name: commit
          description: The precise commit SHA that was fetched by this Task.
        - name: url
          description: The precise URL that was fetched by this Task.
      steps:
        - name: clone
          image: "$(params.gitInitImage)"
          env:
            - name: HOME
              value: "$(params.userHome)"
            - name: PARAM_URL
              value: $(params.url)
            - name: PARAM_REVISION
              value: $(params.revision)
            - name: PARAM_REFSPEC
              value: $(params.refspec)
            - name: PARAM_SUBMODULES
              value: $(params.submodules)
            - name: PARAM_DEPTH
              value: $(params.depth)
            - name: PARAM_SSL_VERIFY
              value: $(params.sslVerify)
            - name: PARAM_CRT_FILENAME
              value: $(params.crtFileName)
            - name: PARAM_SUBDIRECTORY
              value: $(params.subdirectory)
            - name: PARAM_DELETE_EXISTING
              value: $(params.deleteExisting)
            - name: PARAM_HTTP_PROXY
              value: $(params.httpProxy)
            - name: PARAM_HTTPS_PROXY
              value: $(params.httpsProxy)
            - name: PARAM_NO_PROXY
              value: $(params.noProxy)
            - name: PARAM_VERBOSE
              value: $(params.verbose)
            - name: PARAM_SPARSE_CHECKOUT_DIRECTORIES
              value: $(params.sparseCheckoutDirectories)
            - name: PARAM_USER_HOME
              value: $(params.userHome)
            - name: WORKSPACE_OUTPUT_PATH
              value: $(workspaces.output.path)
            - name: WORKSPACE_SSH_DIRECTORY_BOUND
              value: $(workspaces.ssh-directory.bound)
            - name: WORKSPACE_SSH_DIRECTORY_PATH
              value: $(workspaces.ssh-directory.path)
            - name: WORKSPACE_BASIC_AUTH_DIRECTORY_BOUND
              value: $(workspaces.basic-auth.bound)
            - name: WORKSPACE_BASIC_AUTH_DIRECTORY_PATH
              value: $(workspaces.basic-auth.path)
            - name: WORKSPACE_SSL_CA_DIRECTORY_BOUND
              value: $(workspaces.ssl-ca-directory.bound)
            - name: WORKSPACE_SSL_CA_DIRECTORY_PATH
              value: $(workspaces.ssl-ca-directory.path)
          securityContext:
            runAsNonRoot: true
            runAsUser: 65532
          script: |
            #!/usr/bin/env sh
            set -eu
    
            if [ "${PARAM_VERBOSE}" = "true" ] ; then
              set -x
            fi
    
    
            if [ "${WORKSPACE_BASIC_AUTH_DIRECTORY_BOUND}" = "true" ] ; then
              cp "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.git-credentials" "${PARAM_USER_HOME}/.git-credentials"
              cp "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.gitconfig" "${PARAM_USER_HOME}/.gitconfig"
              chmod 400 "${PARAM_USER_HOME}/.git-credentials"
              chmod 400 "${PARAM_USER_HOME}/.gitconfig"
            fi
    
            if [ "${WORKSPACE_SSH_DIRECTORY_BOUND}" = "true" ] ; then
              cp -R "${WORKSPACE_SSH_DIRECTORY_PATH}" "${PARAM_USER_HOME}"/.ssh
              chmod 700 "${PARAM_USER_HOME}"/.ssh
              chmod -R 400 "${PARAM_USER_HOME}"/.ssh/*
            fi
    
            if [ "${WORKSPACE_SSL_CA_DIRECTORY_BOUND}" = "true" ] ; then
               export GIT_SSL_CAPATH="${WORKSPACE_SSL_CA_DIRECTORY_PATH}"
               if [ "${PARAM_CRT_FILENAME}" != "" ] ; then
                  export GIT_SSL_CAINFO="${WORKSPACE_SSL_CA_DIRECTORY_PATH}/${PARAM_CRT_FILENAME}"
               fi
            fi
            CHECKOUT_DIR="${WORKSPACE_OUTPUT_PATH}/${PARAM_SUBDIRECTORY}"
    
            cleandir() {
              # Delete any existing contents of the repo directory if it exists.
              #
              # We don't just "rm -rf ${CHECKOUT_DIR}" because ${CHECKOUT_DIR} might be "/"
              # or the root of a mounted volume.
              if [ -d "${CHECKOUT_DIR}" ] ; then
                # Delete non-hidden files and directories
                rm -rf "${CHECKOUT_DIR:?}"/*
                # Delete files and directories starting with . but excluding ..
                rm -rf "${CHECKOUT_DIR}"/.[!.]*
                # Delete files and directories starting with .. plus any other character
                rm -rf "${CHECKOUT_DIR}"/..?*
              fi
            }
    
            if [ "${PARAM_DELETE_EXISTING}" = "true" ] ; then
              cleandir
            fi
    
            test -z "${PARAM_HTTP_PROXY}" || export HTTP_PROXY="${PARAM_HTTP_PROXY}"
            test -z "${PARAM_HTTPS_PROXY}" || export HTTPS_PROXY="${PARAM_HTTPS_PROXY}"
            test -z "${PARAM_NO_PROXY}" || export NO_PROXY="${PARAM_NO_PROXY}"
    
            /ko-app/git-init \
              -url="${PARAM_URL}" \
              -revision="${PARAM_REVISION}" \
              -refspec="${PARAM_REFSPEC}" \
              -path="${CHECKOUT_DIR}" \
              -sslVerify="${PARAM_SSL_VERIFY}" \
              -submodules="${PARAM_SUBMODULES}" \
              -depth="${PARAM_DEPTH}" \
              -sparseCheckoutDirectories="${PARAM_SPARSE_CHECKOUT_DIRECTORIES}"
            cd "${CHECKOUT_DIR}"
            RESULT_SHA="$(git rev-parse HEAD)"
            EXIT_CODE="$?"
            if [ "${EXIT_CODE}" != 0 ] ; then
              exit "${EXIT_CODE}"
            fi
            printf "%s" "${RESULT_SHA}" > "$(results.commit.path)"
            printf "%s" "${PARAM_URL}" > "$(results.url.path)"
    

一般来说我们只需要提供 output 这个个用于持久化代码的 workspace，然后还包括 url 和 revision 这两个参数，其他使用默认的即可。

## 单元测试

单元测试阶段比较简单，正常来说也是只是单纯执行一个测试命令即可，我们这里没有真正执行单元测试，所以简单测试下即可，编写一个如下所示的 Task：
    
    
    # task-test.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: test
    spec:
      steps:
        - name: test
          image: golang:1.14.2-alpine3.11
          command: ["echo"]
          args: ["this is a test task"]
    

## 编译打包

然后第二个阶段是编译打包阶段，因为我们这个项目的 Dockerfile 不是使用的多阶段构建，所以需要先用一个任务去将应用编译打包成二进制文件，然后将这个编译过后的文件传递到下一个任务进行镜像构建。

我们已经明确了这个阶段要做的事情，编写任务也就简单了，创建如下所的 Task 任务，首先需要通过定义一个 workspace 把 clone 任务里面的代码关联过来：
    
    
    # task-build.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: build
    spec:
      workspaces:
        - name: go-repo
          mountPath: /workspace/repo
      steps:
        - name: build
          image: golang:1.14.2-alpine3.11
          workingDir: /workspace/repo
          script: |
            go build -v -o demo-app
          env:
            - name: GOPROXY
              value: https://goproxy.cn
            - name: GOOS
              value: linux
            - name: GOARCH
              value: amd64
    

这个构建任务也很简单，只是我们将需要用到的环境变量直接通过 `env` 注入了，当然直接写入到 `script` 中也是可以的，或者直接使用 `command` 来执行任务都可以，然后构建生成的 `demo-app` 这个二进制文件保留在代码根目录，这样也就可以通过 workspace 进行共享了。

## Docker 镜像

接下来就是构建并推送 Docker 镜像了，前面我们介绍过使用 Kaniko、DooD、DinD 3 种模式的镜像构建方式，这里我们直接使用 `DinD` 这种模式，我们这里要构建的镜像 Dockerfile 非常简单:
    
    
    FROM alpine
    WORKDIR /home
    
    # 修改alpine源为阿里云
    RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
      apk update && \
      apk upgrade && \
      apk add ca-certificates && update-ca-certificates && \
      apk add --update tzdata && \
      rm -rf /var/cache/apk/*
    
    COPY demo-app /home/
    ENV TZ=Asia/Shanghai
    
    EXPOSE 8080
    
    ENTRYPOINT ./demo-app
    

直接将编译好的二进制文件拷贝到镜像中即可，所以我们这里同样需要通过 Workspace 去获取上一个构建任务的制品，这里我们使用 sidecar 的方式来实现 `DinD` 模式构建镜像，创建一个如下所示的任务：
    
    
    # task-docker.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: docker
    spec:
      workspaces:
        - name: go-repo
      params:
        - name: image
          description: Reference of the image docker will produce.
        - name: registry_mirror
          description: Specific the docker registry mirror
          default: ""
        - name: registry_url
          description: private docker images registry url
      steps:
        - name: docker-build # 构建步骤
          image: docker:stable
          env:
            - name: DOCKER_HOST # 用 TLS 形式通过 TCP 链接 sidecar
              value: tcp://localhost:2376
            - name: DOCKER_TLS_VERIFY # 校验 TLS
              value: "1"
            - name: DOCKER_CERT_PATH # 使用 sidecar 守护进程生成的证书
              value: /certs/client
            - name: DOCKER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: harbor-auth
                  key: password
            - name: DOCKER_USERNAME
              valueFrom:
                secretKeyRef:
                  name: harbor-auth
                  key: username
          workingDir: $(workspaces.go-repo.path)
          script: | # docker 构建命令
            docker login $(params.registry_url) -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
            docker build --no-cache -f ./Dockerfile -t $(params.image) .
            docker push $(params.image)
          volumeMounts: # 声明挂载证书目录
            - mountPath: /certs/client
              name: dind-certs
      sidecars: # sidecar 模式，提供 docker daemon服务，实现真正的 DinD 模式
        - image: docker:dind
          name: server
          args:
            - --storage-driver=vfs
            - --userland-proxy=false
            - --debug
            - --insecure-registry=$(params.registry_url)
            - --registry-mirror=$(params.registry_mirror)
          securityContext:
            privileged: true
          env:
            - name: DOCKER_TLS_CERTDIR # 将生成的证书写入与客户端共享的路径
              value: /certs
          volumeMounts:
            - mountPath: /certs/client
              name: dind-certs
            - mountPath: /var/lib/docker
              name: docker-root
          readinessProbe: # 等待 dind daemon 生成它与客户端共享的证书
            periodSeconds: 1
            exec:
              command: ["ls", "/certs/client/ca.pem"]
      volumes: # 使用 emptyDir 的形式即可
        - name: dind-certs
          emptyDir: {}
        - name: docker-root
          persistentVolumeClaim:
            claimName: docker-root-pvc
    

这个任务的重点还是要去声明一个 Workspace，当执行任务的时候要使用和前面构建任务同一个 Workspace，这样就可以获得上面编译成的 `demo-app` 这个二进制文件了。

## 部署

接下来的部署阶段，我们同样可以参考之前 Jenkins 流水线里面的实现，由于项目中我们包含了 Helm Chart 包，所以直接使用 Helm 来部署即可，要实现 Helm 部署，当然我们首先需要一个包含 `helm` 命令的镜像，当然完全可以自己去编写一个这样的任务，此外我们还可以直接去 `hub.tekton.dev` 上面查找 Catalog，因为这上面就有很多比较通用的一些任务了，比如 [helm-upgrade-from-source](https://hub.tekton.dev/tekton/task/helm-upgrade-from-source) 这个 Task 任务就完全可以满足我们的需求了：

![helm tekton](https://picdn.youdianzhishi.com/images/20210626154922.png)

这个 Catalog 下面也包含完整的使用文档了，我们可以将该任务直接下载下来根据我们自己的需求做一些定制修改，如下所示：
    
    
    # task-deploy.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: deploy
      labels:
        app.kubernetes.io/version: "0.3"
      annotations:
        tekton.dev/pipelines.minVersion: "0.12.1"
        tekton.dev/categories: Deployment
        tekton.dev/tags: helm
        tekton.dev/platforms: "linux/amd64,linux/s390x,linux/ppc64le,linux/arm64"
    spec:
      description: >-
        These tasks will install / upgrade a helm chart into your Kubernetes /
        OpenShift Cluster using Helm
    
      params:
        - name: charts_dir
          description: The directory in source that contains the helm chart
        - name: release_version
          description: The helm release version in semantic versioning format
          default: "v1.0.0"
        - name: release_name
          description: The helm release name
          default: "helm-release"
        - name: release_namespace
          description: The helm release namespace
          default: ""
        - name: overwrite_values
          description: "Specify the values you want to overwrite, comma separated: autoscaling.enabled=true,replicas=1"
          default: ""
        - name: values_file
          description: "The values file to be used"
          default: "values.yaml"
        - name: helm_image
          description: "helm image to be used"
          default: "docker.io/lachlanevenson/k8s-helm@sha256:5c792f29950b388de24e7448d378881f68b3df73a7b30769a6aa861061fd08ae" #tag: v3.6.0
        - name: upgrade_extra_params
          description: "Extra parameters passed for the helm upgrade command"
          default: ""
      workspaces:
        - name: source
      results:
        - name: helm-status
          description: Helm deploy status
      steps:
        - name: upgrade
          image: $(params.helm_image)
          workingDir: /workspace/source
          script: |
            echo current installed helm releases
            helm list --namespace "$(params.release_namespace)"
    
            echo installing helm chart...
            helm upgrade --install --wait --values "$(params.charts_dir)/$(params.values_file)" --namespace "$(params.release_namespace)" --version "$(params.release_version)" "$(params.release_name)" "$(params.charts_dir)" --debug --set "$(params.overwrite_values)" $(params.upgrade_extra_params)
    
            status=`helm status $(params.release_name) --namespace "$(params.release_namespace)" | awk '/STATUS/ {print $2}'`
            echo ${status} | tr -d "\n" | tee $(results.helm-status.path)
    

因为我们的 Helm Chart 模板就在代码仓库中，所以不需要从 Chart Repo 仓库中获取，只需要指定 Chart 路径即可，其他可配置的参数都通过 `params` 参数暴露出去了，非常灵活，最后我们还获取了 Helm 部署的状态，写入到了 Results 中，方便后续任务处理。

## 回滚

最后应用部署完成后可能还需要回滚，因为可能部署的应用有错误，当然这个回滚动作最好是我们自己去触发，但是在某些场景下，比如 helm 部署已经明确失败了，那么我们当然可以自动回滚了，所以就需要判断当部署失败的时候再执行回滚，也就是这个任务并不是一定会发生的，只在某些场景下才会出现，我们可以在流水线中通过使用 `WhenExpressions` 来实现这个功能。要只在满足某些条件时运行任务，可以使用 `when` 字段来保护任务执行，when 字段允许你列出对 `WhenExpressions` 的一系列引用。

`WhenExpressions` 由 `Input`、`Operator` 和 `Values` 几部分组成：

  * `Input` 是 `WhenExpressions` 的输入，它可以是一个静态的输入或变量（Params 或 Results），如果未提供输入，则默认为空字符串
  * `Operator` 是一个运算符，表示 Input 和 Values 之间的关系，有效的运算符包括 `in`、`notin`
  * `Values` 是一个字符串数组，必须提供一个非空的 Values 数组，它同样可以包含静态值或者变量（Params、Results 或者 Workspaces 绑定）



当在一个 Task 任务中配置了 `WhenExpressions`，在执行 Task 之前会评估声明的 `WhenExpressions`，如果结果为 True，则执行任务，如果为 False，则不会执行该任务。

我们这里创建的回滚任务如下所示：
    
    
    # task-rollback.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: rollback
    spec:
      params:
        - name: release_name
          description: The helm release name
        - name: release_namespace
          description: The helm release namespace
          default: ""
        - name: helm_image
          description: "helm image to be used"
          default: "docker.io/lachlanevenson/k8s-helm@sha256:5c792f29950b388de24e7448d378881f68b3df73a7b30769a6aa861061fd08ae" #tag: v3.6.0
      steps:
        - name: rollback
          image: $(params.helm_image)
          script: |
            echo rollback current installed helm releases
            helm rollback $(params.release_name) --namespace $(params.release_namespace)
    

## 流水线

现在我们的整个工作流任务都已经创建完成了，接下来我们就可以将这些任务全部串联起来组成一个 Pipeline 流水线了，将上面定义的几个 Task 引用到 Pipeline 中来，当然还需要声明 Task 中用到的 resources 或者 workspaces 这些数据：
    
    
    # pipeline.yaml
    apiVersion: tekton.dev/v1beta1
    kind: Pipeline
    metadata:
      name: pipeline
    spec:
      workspaces: # 声明 workspaces
        - name: go-repo-pvc
      params:
        # 定义代码仓库
        - name: git_url
        - name: revision
          type: string
          default: "main"
        # 定义镜像参数
        - name: image
        - name: registry_url
          type: string
          default: "harbor.k8s.local"
        - name: registry_mirror
          type: string
          default: "https://mirror.baidubce.com"
        # 定义 helm charts 参数
        - name: charts_dir
        - name: release_name
        - name: release_namespace
          default: "default"
        - name: overwrite_values
          default: ""
        - name: values_file
          default: "values.yaml"
      tasks: # 添加task到流水线中
        - name: clone
          taskRef:
            name: git-clone
          workspaces:
            - name: output
              workspace: go-repo-pvc
          params:
            - name: url
              value: $(params.git_url)
            - name: revision
              value: $(params.revision)
        - name: test
          taskRef:
            name: test
          runAfter:
            - clone
        - name: build # 编译二进制程序
          taskRef:
            name: build
          runAfter: # 测试任务执行之后才执行 build task
            - test
            - clone
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
        - name: docker # 构建并推送 Docker 镜像
          taskRef:
            name: docker
          runAfter:
            - build
          workspaces: # 传递 workspaces
            - name: go-repo
              workspace: go-repo-pvc
          params: # 传递参数
            - name: image
              value: $(params.image)
            - name: registry_url
              value: $(params.registry_url)
            - name: registry_mirror
              value: $(params.registry_mirror)
        - name: deploy # 部署应用
          taskRef:
            name: deploy
          runAfter:
            - docker
          workspaces:
            - name: source
              workspace: go-repo-pvc
          params:
            - name: charts_dir
              value: $(params.charts_dir)
            - name: release_name
              value: $(params.release_name)
            - name: release_namespace
              value: $(params.release_namespace)
            - name: overwrite_values
              value: $(params.overwrite_values)
            - name: values_file
              value: $(params.values_file)
        - name: rollback # 回滚
          taskRef:
            name: rollback
          when:
            - input: "$(tasks.deploy.results.helm-status)"
              operator: in
              values: ["failed"]
          params:
            - name: release_name
              value: $(params.release_name)
            - name: release_namespace
              value: $(params.release_namespace)
    

整体流程比较简单，就是在 Pipeline 需要先声明使用到的 Workspace、Resource、Params 这些资源，然后将声明的数据传递到 Task 任务中去，需要注意的是最后一个回滚任务，我们需要根据前面的 `deploy` 任务的结果来判断是否需要执行该任务，所以这里我们使用了 `when` 属性，通过 `$(tasks.deploy.results.helm-status)` 获取部署状态。

## 执行流水线

现在我们就可以来执行下我们的流水线，看是否符合我们自身的要求，首先我们需要先创建关联的其他资源对象，比如 Workspace 对应的 PVC、还有 GitLab、Harbor 的认证信息：
    
    
    # other.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: gitlab-auth
      annotations:
        tekton.dev/git-0: http://git.k8s.local
    type: kubernetes.io/basic-auth
    stringData:
      username: root
      password: admin321
    
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: harbor-auth
      annotations:
        tekton.dev/docker-0: http://harbor.k8s.local
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: Harbor12345
    
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: tekton-build-sa
    secrets:
      - name: harbor-auth
      - name: gitlab-auth
    
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: tekton-clusterrole-binding
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: edit
    subjects:
      - kind: ServiceAccount
        name: tekton-build-sa
        namespace: default
    
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: go-repo-pvc
    spec:
      resources:
        requests:
          storage: 1Gi
      volumeMode: Filesystem
      storageClassName: nfs-client # 使用 StorageClass 自动生成 PV
      accessModes:
        - ReadWriteOnce
    
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: docker-root-pvc
    spec:
      resources:
        requests:
          storage: 2Gi
      volumeMode: Filesystem
      storageClassName: nfs-client # 使用 StorageClass 自动生成 PV
      accessModes:
        - ReadWriteOnce
    

这些关联的资源对象创建完成后，还需要为上面的 ServiceAccount 绑定一个权限，因为在 Helm 容器中我们要去操作一些集群资源，必然需要先做权限声明，这里我们可以将 `tekton-build-sa` 绑定到 `edit` 这个 ClusterRole 上去。

我们接下来就可以创建一个 PipelineRun 资源对象来触发我们的流水线构建了：
    
    
    # pipelinerun.yaml
    apiVersion: tekton.dev/v1beta1
    kind: PipelineRun
    metadata:
      name: pipelinerun
    spec:
      serviceAccountName: tekton-build-sa
      pipelineRef:
        name: pipeline
      workspaces:
        - name: go-repo-pvc
          persistentVolumeClaim:
            claimName: go-repo-pvc
      params:
        - name: git_url
          value: http://git.k8s.local/course/devops-demo.git
        - name: image
          value: "harbor.k8s.local/course/devops-demo:v0.1.0"
        - name: charts_dir
          value: "./helm"
        - name: release_name
          value: devops-demo
        - name: release_namespace
          value: "kube-ops"
        - name: overwrite_values
          value: "image.repository=harbor.k8s.local/course/devops-demo,image.tag=v0.1.0"
        - name: values_file
          value: "my-values.yaml"
    

直接创建上面的资源对象就可以执行我们的 Pipeline 流水线了:
    
    
    $ kubectl apply -f pipelinerun.yaml
    $ tkn pr describe pipelinerun
    Name:              pipelinerun
    Namespace:         default
    Pipeline Ref:      pipeline
    Service Account:   tekton-build-sa
    Timeout:           1h0m0s
    Labels:
     tekton.dev/pipeline=pipeline
    
    🌡️  Status
    
    STARTED         DURATION   STATUS
    4 minutes ago   2m30s      Succeeded(Completed)
    
    ⚓ Params
    
     NAME                  VALUE
     ∙ git_url             http://git.k8s.local/course/devops-demo.git
     ∙ image               harbor.k8s.local/course/devops-demo:v0.1.0
     ∙ charts_dir          ./helm
     ∙ release_name        devops-demo
     ∙ release_namespace   kube-ops
     ∙ overwrite_values    image.repository=harbor.k8s.local/course/devops-demo,image.tag=v0.1.0
     ∙ values_file         my-values.yaml
    
    📂 Workspaces
    
     NAME            SUB PATH   WORKSPACE BINDING
     ∙ go-repo-pvc   ---        PersistentVolumeClaim (claimName=go-repo-pvc)
    
    🗂  Taskruns
    
     NAME                   TASK NAME   STARTED         DURATION   STATUS
     ∙ pipelinerun-deploy   deploy      3 minutes ago   1m14s      Succeeded
     ∙ pipelinerun-docker   docker      4 minutes ago   55s        Succeeded
     ∙ pipelinerun-build    build       4 minutes ago   11s        Succeeded
     ∙ pipelinerun-test     test        4 minutes ago   4s         Succeeded
     ∙ pipelinerun-clone    clone       4 minutes ago   6s         Succeeded
    
    ⏭️  Skipped Tasks
    
     NAME
     ∙ rollback
    
    # 部署成功了
    $ curl devops-demo.k8s.local
    {"msg":"Hello DevOps On Kubernetes"}
    

在 Dashboard 上也可以看到可以流水线可以正常执行，由于部署成功了，所以 rollback 回滚的任务也就被忽略了：

![pipeline deployed](https://picdn.youdianzhishi.com/images/1660201718899.png)

## 触发器

整个流水线已经成功执行了，接下来最后一步就是将 Gitlab 和 Tekton 进行对接，也就是通过 Tekton Trigger 来自动触发构建。关于 Tekton Trigger 的使用前面我们已经详细讲解过了，细节就不过多讨论。

首先添加一个用于 Gitlab Webhook 访问的 Secret Token，同样要将这个 Secret 关联到上面使用的 ServiceAccount 上面去，然后继续添加对应的 RBAC 权限：
    
    
    # other.yaml
    # ......
    apiVersion: v1
    kind: Secret
    metadata:
      name: gitlab-secret
    type: Opaque
    stringData:
      secretToken: "1234567"
    
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: tekton-build-sa
    secrets:
      - name: harbor-auth
      - name: gitlab-auth
      - name: gitlab-secret
    
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: tekton-triggers-gitlab-minimal
    rules:
      # EventListeners need to be able to fetch all namespaced resources
      - apiGroups: ["triggers.tekton.dev"]
        resources:
          ["eventlisteners", "triggerbindings", "triggertemplates", "triggers"]
        verbs: ["get", "list", "watch"]
      - apiGroups: [""]
        # configmaps is needed for updating logging config
        resources: ["configmaps"]
        verbs: ["get", "list", "watch"]
      # Permissions to create resources in associated TriggerTemplates
      - apiGroups: ["tekton.dev"]
        resources: ["pipelineruns", "pipelineresources", "taskruns"]
        verbs: ["create"]
      - apiGroups: [""]
        resources: ["serviceaccounts"]
        verbs: ["impersonate"]
      - apiGroups: ["policy"]
        resources: ["podsecuritypolicies"]
        resourceNames: ["tekton-triggers"]
        verbs: ["use"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: tekton-triggers-gitlab-binding
    subjects:
      - kind: ServiceAccount
        name: tekton-build-sa
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: tekton-triggers-gitlab-minimal
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: tekton-triggers-gitlab-clusterrole
    rules:
      # EventListeners need to be able to fetch any clustertriggerbindings
      - apiGroups: ["triggers.tekton.dev"]
        resources: ["clustertriggerbindings", "clusterinterceptors"]
        verbs: ["get", "list", "watch"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: tekton-triggers-gitlab-clusterbinding
    subjects:
      - kind: ServiceAccount
        name: tekton-build-sa
        namespace: default
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: tekton-triggers-gitlab-clusterrole
    

接着就可以来创建 EventListener 资源对象了，用来接收 Gitlab 的 Push Event 事件，如下所示：
    
    
    # gitlab-listener.yaml
    apiVersion: triggers.tekton.dev/v1beta1
    kind: EventListener
    metadata:
      name: gitlab-listener # 该事件监听器会创建一个名为el-gitlab-listener的Service对象
    spec:
      serviceAccountName: tekton-build-sa
      triggers:
        - name: gitlab-push-events-trigger
          interceptors:
            - ref:
                name: gitlab
              params:
                - name: secretRef # 引用 gitlab-secret 的 Secret 对象中的 secretToken 的值
                  value:
                    secretName: gitlab-secret
                    secretKey: secretToken
                - name: eventTypes
                  value:
                    - Push Hook # 只接收 GitLab Push 事件
          bindings: # 定义TriggerBinding，配置参数
            - name: gitrevision
              value: $(body.checkout_sha)
            - name: gitrepositoryurl
              value: $(body.repository.git_http_url)
          template:
            ref: gitlab-template
    

上面我们通过 TriggerBinding 定义了两个参数 `gitrevision`、`gitrepositoryurl`，这两个参数的值可以通过 Gitlab 发送过来的 POST 请求中获取到数据，然后我们就可以将这两个参数传递到 `TriggerTemplate` 对象中去，这里的模板其实也就是将上面我们定义的 PipelineRun 对象模板化而已，主要是替换 `git_url` 和镜像 TAG 这两个参数，如下所示：
    
    
    # gitlab-template.yaml
    apiVersion: triggers.tekton.dev/v1beta1
    kind: TriggerTemplate
    metadata:
      name: gitlab-template
    spec:
      params: # 定义参数，和 TriggerBinding 中的保持一致
        - name: gitrevision
        - name: gitrepositoryurl
      resourcetemplates: # 定义资源模板
        - apiVersion: tekton.dev/v1beta1
          kind: PipelineRun # 定义 pipeline 模板
          metadata:
            generateName: gitlab-run- # TaskRun 名称前缀
          spec:
            serviceAccountName: tekton-build-sa
            pipelineRef:
              name: pipeline
            workspaces:
              - name: go-repo-pvc
                persistentVolumeClaim:
                  claimName: go-repo-pvc
            params:
              - name: git_url
                value: $(tt.params.gitrepositoryurl)
              - name: image
                value: "harbor.k8s.local/course/devops-demo:$(tt.params.gitrevision)"
              - name: charts_dir
                value: "./helm"
              - name: release_name
                value: devops-demo
              - name: release_namespace
                value: "kube-ops"
              - name: overwrite_values
                value: "image.repository=harbor.k8s.local/course/devops-demo,image.tag=$(tt.params.gitrevision)"
              - name: values_file
                value: "my-values.yaml"
    

直接创建上面新建的几个资源对象即可，这会创建一个 eventlistern 服务用来接收 Webhook 请求：
    
    
    $ kubectl get eventlistener gitlab-listener
    NAME              ADDRESS                                                    AVAILABLE   REASON                     READY   REASON
    gitlab-listener   http://el-gitlab-listener.default.svc.cluster.local:8080   True        MinimumReplicasAvailable   True
    

所以一定还要记得在 Gitlab 仓库中配置上 Webhook：

![gitlab webhook](https://picdn.youdianzhishi.com/images/1660202018469.png)

这样我们整个触发器和监听器就配置好了，接下来我们去修改下我们的项目代码，然后提交代码，正常提交过后就会在集群中创建一个 PipelinRun 对象用来执行我们的流水线了。

![触发PipelineRun](https://picdn.youdianzhishi.com/images/1660202849049.png)
    
    
    $ kubectl get pipelinerun
    NAME               SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
    gitlab-run-j77rx   True        Completed   4m46s       46s
    $ curl devops-demo.k8s.local
    {"msg":"Hello Tekton On Kubernetes"}
    

可以看到流水线执行成功后，应用已经成功部署了我们新提交的代码，到这里我们就完成了使用 Tekton 来重构项目的流水线。
