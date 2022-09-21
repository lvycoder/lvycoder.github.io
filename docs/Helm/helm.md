# **Helm 配置grafana**

## **获取Token**
参考: [官网](https://grafana.com/docs/grafana/latest/developers/http_api/create-api-tokens-for-org/#how-to-add-a-dashboard)

```
curl -X POST -H "Content-Type: application/json" -d '{"name":"apikeycurl", "role": "Admin"}' http://admin:strongpassword@localhost:3000/api/auth/keys
{"id":1,"name":"apikeycurl","key":"eyJrIjoiVHV2czQxNTdiQnFEWDJ6VjRXMjJpUTc1bGtkR2NmQUoiLCJuIjoiYXBpa2V5Y3VybCIsImlkIjoxfQ=="}%
```

## **打开dashboardProviders**

!!! info "注意"
    注意去掉dashboardProviders后面的{}

```yaml
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

# 添加官网dashboard

dashboards:
  default:
    ceph-cluster:
      gnetId: 2842
      revision: 14
      datasource: Prometheus
    ceph-osd:
      gnetId: 5336
      revision: 5
      datasource: Prometheus
    ceph-pools:
      gnetId: 5342
      revision: 5
      datasource: Prometheus
      token: 'eyJrIjoiVHV2czQxNTdiQnFEWDJ6VjRXMjJpUTc1bGtkR2NmQUoiLCJuIjoiYXBpa2V5Y3VybCIsImlkIjoxfQ=='
```
