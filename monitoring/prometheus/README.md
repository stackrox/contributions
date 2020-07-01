# Prometheus Kubernetes

## Apply

Clone:

```bash
git clone https://github.com/clemenko/prometheus
cd prometheus/k8s
kubectl apply -f .
```

## Grafana Login

Find the exposed port for Grafana.

```bash
kubectl get svc -n monitoring
```

And login with `admin/Pa22word`.
