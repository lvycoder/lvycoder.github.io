
kubectl apply -f deploy/crds/redis.kun_distributedredisclusters_crd.yaml
kubectl apply -f deploy/crds/redis.kun_redisclusterbackups_crd.yaml
 

k create ns redis-cluster


kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/namespace/role.yaml
kubectl apply -f deploy/namespace/role_binding.yaml
kubectl apply -f deploy/namespace/operator.yaml

helm repo add ucloud-operator https://ucloud.github.io/redis-cluster-operator/
helm repo update

helm install --generate-name ucloud-operator/redis-cluster-operator

kubectl apply -f deploy/example/redis.kun_v1alpha1_distributedrediscluster_cr.yaml