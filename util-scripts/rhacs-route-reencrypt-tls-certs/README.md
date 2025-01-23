# Set up ACS Passthrough TLS Routes with Central's CA

Get rid of the cert errors when accessing the Central web UI by
adding the Central certs to Central's Route

This is a one liner.

Must be logged in to OpenShift as cluster-admin.

**Required Environment Vars:**
* logged into OpenShift as cluster-admin.

**Required Tools:**
* `bash`
* `oc` logged into the OpenShift Cluster with ACS already installed.
* `sed`

**Output:**
* No output

**Usage:**
`./acs-route-passthrough-tls-certs.sh`

