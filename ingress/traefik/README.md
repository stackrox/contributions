# Traefik is the best

## What

[Traefik](https://containo.us/traefik/)

## How

Deploy the included Traefik CRD (Custom Resource Definition). The CRD file includes the LoadBalancer Service object as well. This file also includes the NameSpace and ClusterRole stuff.

```bash
kubectl apply -f traefik_crd_deployment.yml
```

## But wait

There is more. Also included is `stackrox_traefik_crd.yml` which contains the IngressRoute for the Traefik dashboard and the IngressRouteTCP for Stackrox. You will have to change the URL names in the file that fit your domain.

```bash
kubectl apply -f stackrox_traefik_crd.yml
```

## Profit
