## Integrating Red Hat Advanced Cluster Security (ACS) with OpenShift Lightspeed

This guide describes how to connect ACS Central to the OpenShift Lightspeed API so
that Central can generate **AI risk summaries**. It covers only the ACS-specific
integration — it assumes OpenShift Lightspeed is already deployed, configured, and
working.

**Note:** Instructions provided in this guide are provided as-is without warranty
or support from Red Hat.

### Prerequisites

- ACS Central and OpenShift Lightspeed are running on the **same** OpenShift
  cluster.
- OpenShift Lightspeed has already been deployed and set up by following the
  official OpenShift Lightspeed documentation, and its chat is confirmed working.
- `oc` is logged in with `cluster-admin` privileges (or an account that can create
  `NetworkPolicy` and `ClusterRoleBinding` resources).
- Central runs in the `stackrox` namespace using the `central` service account
  (the ACS defaults). If your installation differs, adjust the namespace / service
  account / pod label references in the example manifests below.

### 1. Ensure Lightspeed is running and chat works

This integration only works once Lightspeed itself is healthy, so confirm that
first.

```bash
oc get pods -n openshift-lightspeed   # the app-server pod should be Running
```

Open the OpenShift web console, click the **Lightspeed** button (bottom-left
corner), and send a test prompt such as `Test`. A reply from the LLM confirms that
Lightspeed is set up correctly. Do not continue until the chat works.

### 2. Apply the NetworkPolicy

OpenShift Lightspeed restricts ingress to its API. This `NetworkPolicy` allows the
`central` pod in the `stackrox` namespace to reach the Lightspeed API on TCP port
`8443`.

```bash
oc apply -f networkpolicy.yaml
```

`networkpolicy.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-acs-to-lightspeed
  namespace: openshift-lightspeed
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: openshift-lightspeed
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: stackrox
          podSelector:
            matchLabels:
              app: central
      ports:
        - protocol: TCP
          port: 8443
```

### 3. Apply the ClusterRoleBinding

Central needs permission to query the Lightspeed API. This `ClusterRoleBinding`
grants the `central` service account the `lightspeed-operator-query-access`
`ClusterRole`, which is created by the OpenShift Lightspeed operator.

```bash
oc apply -f rolebinding.yaml
```

`rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: acs-lightspeed-query-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: lightspeed-operator-query-access
subjects:
  - kind: ServiceAccount
    name: central
    namespace: stackrox
```

### 4. Verify the AI risk summary in Central

With network access and RBAC in place, confirm the feature end-to-end in the
Central UI: open a deployment's risk details and click the **Investigate with AI** button.
A generated summary confirms that Central can reach and query the Lightspeed API.

### 5. Configuration options

The following environment variables on Central can tune this integration. Set them
using the method that matches how you installed ACS (ACS Operator, Helm, etc.) —
see the official Red Hat documentation on
[customizing Central with the ACS Operator](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest/html/installing/installing-rhacs-on-red-hat-openshift#secured-cluster-services-environment-variables_install-secured-cluster-ocp)
(`spec.customize.envVars`) for how to apply environment variables.

- **`ROX_LIGHTSPEED_RISK_SUMMARY`** — enables or disables the AI risk summary
  feature in Central. Can be `true` or `false`. Default: `true`.
- **`ROX_LIGHTSPEED_ENDPOINT`** — overrides the Lightspeed API URL that Central
  calls. Default: `https://lightspeed-app-server.openshift-lightspeed.svc:8443`.
