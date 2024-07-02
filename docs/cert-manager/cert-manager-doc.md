
## Cert-manager 安装

```
helm upgrade --install \    
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.1 \
  -f ./values.yaml
```

values 配置文件：

```yaml
installCRDs: true

extraArgs:
  - --enable-certificate-owner-ref=true
  - --dns01-recursive-nameservers-only
  - --dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53
```

!!! warning 温馨提示
    在使用cert-manager对接cloudflare时，出现了DNS无法验证的情况，具体内容可以看下来的issues，解决办法解释加上values中的内容。

## 问题处理

- https://github.com/cert-manager/cert-manager/issues/5917
