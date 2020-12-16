# Istio Gateway Ingress configuration for StackRox Central

This configuration provides a simple Istio Gateway ssl-passthrough ingress for StackRox Central. Tested on Istio v1.8.

## Notes
* By default, Istio's Ingress Gateway creates a loadbalancer service. You can see the assigned IP or hostname using `kubectl -n istio-system get svc`
* Routing to appropriate backend depends on DNS. This YAML uses `central.example.com` which should be customized for your environment

## Files
* `central-istio-gw-passthrough.yaml` The Gateway, VirtualService, and DestinationRule  definitions for the stackrox namespace

OWNER: srcporter

LAST TESTED VERSION: 3.0.52.1
