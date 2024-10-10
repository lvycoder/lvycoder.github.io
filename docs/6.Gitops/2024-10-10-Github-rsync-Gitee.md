国内由于网络的原因需要科学上网才能访问 github 的仓库,但是我又想把我的仓库同步一份到我们国内的 gitee 上.(利用 github action 来实现)
1. 实时备份(github 提交代码之后会直接同步 gitee),代码的安全性可以保证
2. 在国内部署 gitops 服务可以通过拉取 gitee 的代码实现自动化的 gitops 流程,来自动部署或者发布.

首先你需要注册一个 gitee 的账号.
- 注册之后需要获取一个 token 来方便我们 github action 使用

我的项目目录结构
```
cd .github/workflows
$ tree                                                                                                                                                                                                                                           (csg/infra)
.
├── ci.yaml
└── sync-to-gitee.yml

```

其中 sync-to-gitee 就是我们同步的配置文件

需要添加:

- target-url
- target-username
- target-token

```
$ cat sync-to-gitee.yml                                                                                                                                                                                                                          (csg/infra)
name: sync-gitee
on:
  push:
    branches:
      - '**'

jobs:
  sync:
    runs-on: ubuntu-latest
    name: Git Repo Sync
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 0
    - uses: wangchucheng/git-repo-sync@v0.1.0
      with:
        # Such as https://github.com/wangchucheng/git-repo-sync.git
        target-url: https://gitee.com/awxie/lvycoder.github.io.git
        # Such as wangchucheng
        target-username: awxie
        # You can store token in your project's 'Setting > Secrets' and reference the name here. Such as ${{ secrets.ACCESS_TOKEN }}
        target-token:  xxxxxxxxxxxxxxx
```
