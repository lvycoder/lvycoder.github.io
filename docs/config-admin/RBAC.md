# **RBAC 鉴权**

!!! note "核心概念"
    - Role : Role 总是用来在某个名字空间内设置访问权限； 在你创建 Role 时，你必须指定该 Role 所属的名字空间。(有命令空间限制)
    - ClusterRole: ClusterRole 则是一个集群作用域的资源(没有命名空间限制)
    - RoleBinding: 角色绑定(有命令空间限制)
    - ClusterRoleBinding: 角色绑定(无命令空间限制)
## ** 细粒度的权限划分**




## **Role示例**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default   # 有命名空间限制
  name: pod-reader
rules:
- apiGroups: [""] # "" 标明 core API 组
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```


## **ClusterRole 示例**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" 被忽略，因为 ClusterRoles 不受名字空间限制
  name: secret-reader
rules:
- apiGroups: [""]
  # 在 HTTP 层面，用来访问 Secret 资源的名称为 "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

!!! help "两者的区别"
    主要在命名空间限制上，clusterRole没有命名空间限制，Role有限制