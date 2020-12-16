# Traefik ingress configuration for StackRox Central

This configuration provides a Traefik ingress definition for StackRox central which terminates TLS at the Ingress and connects to Central over TLS

## Traefik config
* Strongly recommended that Traefik be configured to accept TLS connections at the *frontend*. In the ingress example here, the TLS certificate presented by Traefik is in the secret `stackrox-central-tls`. This certificate can be self-signed or publicly signed, but must be compatible with the requirements that Traefik documents at https://doc.traefik.io/traefik/v1.7/user-guide/kubernetes/#add-a-tls-certificate-to-the-ingress
* In order to make a TLS connection to StackRox Central on the *backend*, the certificate used by central must either be signed by a trusted root (recommended), or Traefik must be configured with the --insecureskipverify option.
* Traefik configurations with TLS router can avoid the certificate configuration with the passthrough option https://doc.traefik.io/traefik/routing/routers/#passthrough

## Notes
* Note that if you use a self-signed certificate for the any Ingress frontend, StackRox Sensors in remote clusters must be configured to trust that certificate https://help.stackrox.com/docs/configure-stackrox/configure-custom-certificates/#configure-sensor-to-trust-custom-certificates
* Routing to appropriate backend depends on DNS. This YAML uses `central.example.com` which should be customized for your environment

## Files
* `central-traefik-ingress.yaml` Central Ingress definition for Traefik

OWNER: srcporter

LAST TESTED VERSION: 3.0.52.1
