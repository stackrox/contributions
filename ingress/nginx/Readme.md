# Nginx Ingress configuration for StackRox Central

This configuration provides two examples for Kubernetes Nginx Ingress

Note that these apply to the open-source [Kubernetes nginx ingress](https://kubernetes.github.io/ingress-nginx/) and **not** the nginx plus family of products.

## Files
* `central-nginx-passthrough-ingress.yaml` Central-ingress definition for the stackrox namespace that uses ssl-passthrough.
* `central-nginx-encrypt-ingress.yaml` Central-ingress that terminates TLS at nginx, and re-encrypts to the Central service. Customization of hostnames and certificate secrets is recommended.


NOTE: in order to use the ssl-passthrough annotation and have it work correctly, the nginx ingress controller must be deployed with the `--enable-ssl-passthrough` option.

Please review the [documentation for TLS/HTTPS](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#ssl-passthrough) on nginx ingress.

In a standard installation of the ingress controller you can add this to a running pod with:

`kubectl edit nginx-ingress-controller -n kube-system`

and appending to the arguments in the containers spec:
`    spec:
      containers:
      - args:
        - /nginx-ingress-controller
        - --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
        - --election-id=ingress-controller-leader
        - --ingress-class=nginx
        - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
        - --validating-webhook=:8443
        - --validating-webhook-certificate=/usr/local/certificates/cert
        - --validating-webhook-key=/usr/local/certificates/key
        - --enable-ssl-passthrough`

OWNER: srcporter  
LAST TESTED VERSION: 3.0.54.0
