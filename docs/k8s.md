# etcd 备份

```
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /srv/data/etcd-snapshot.db
```

## 备份



## 恢复
