!#/bin/bash

# on openshift, set up acs reencrypt routes with Central's CA

oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: central
  namespace: {{ .Values.stackrox_namespace }}
spec:
  tls:
    termination: reencrypt
    destinationCACertificate: |
$(oc extract secret/central-tls -n {{ .Values.stackrox_namespace }} --keys ca.pem --to=- | sed 's/^/      /' )
EOF


