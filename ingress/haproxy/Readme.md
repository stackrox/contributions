# HAProxy Ingress configuration for StackRox Central

This configuration provides a simple HAProxy ssl-passthrough ingress for StackRox Central. 

## Files
* `central-hap-ingress.yaml` The central-ingress definition for the stackrox namespace
* `haproxy-controller.yaml` Example HAProxy controller configuration with ssl-passthrough enabled. If you're running HAProxy controller already, you'll probably only need the lines from the ConfigMap section to enable ssl-passthrough. 
