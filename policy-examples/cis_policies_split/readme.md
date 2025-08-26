# CIS Policy Files - Clean Naming Convention

This directory contains CIS (Center for Internet Security) policy files converted to YAML format with clean, readable filenames.

## File Organization

### Docker Policies (docker-*.yaml)
- `docker-4.1-no-root-user.yaml` - Ensure image is not running as root
- `docker-4.2-trusted-base-images.yaml` - Ensure containers use only trusted base images
- `docker-4.3-no-unnecessary-packages.yaml` - Ensure unnecessary packages are not installed
- `docker-4.4-image-scanning.yaml` - Ensure images are scanned and rebuilt for security patches
- `docker-4.5-content-trust.yaml` - Ensure Content trust for Docker is enabled
- `docker-4.6-healthcheck.yaml` - Ensure HEALTHCHECK instruction is added to container image
- `docker-4.7-no-sensitive-mounts.yaml` - Ensure sensitive host system directories are not mounted
- `docker-5.1-apparmor-profile.yaml` - Ensure AppArmor Profile is enabled
- `docker-5.2-selinux-options.yaml` - Ensure SELinux security options are set if applicable
- `docker-5.7-no-privileged-ports.yaml` - Ensure privileged ports are not mapped
- `docker-5.8-no-shared-user-namespaces.yaml` - Ensure host's user namespaces are not shared
- `docker-5.9-no-shared-network-namespaces.yaml` - Ensure host's network namespace is not shared
- `docker-5.10-memory-limits.yaml` - Ensure memory usage for container is limited
- `docker-5.11-cpu-priority.yaml` - Ensure CPU priority is set appropriately on the container
- `docker-5.12-readonly-rootfs.yaml` - Ensure container's root filesystem is mounted as read-only
- `docker-5.25-no-privilege-escalation.yaml` - Ensure container is restricted from acquiring additional privileges

### Kubernetes Policies (k8s-*.yaml)
- `k8s-5.1.1-no-privileged-containers.yaml` - Minimize privileged containers
- `k8s-5.1.2-no-host-network.yaml` - Minimize hostNetwork usage
- `k8s-5.1.3-no-host-pid-ipc.yaml` - Minimize hostPID and hostIPC usage
- `k8s-5.1.4-no-privilege-escalation.yaml` - Minimize allowPrivilegeEscalation
- `k8s-5.1.5-no-root-containers.yaml` - Minimize root containers
- `k8s-5.1.6-minimize-capabilities.yaml` - Minimize capabilities
- `k8s-5.2.1-no-privilege-escalation-admission.yaml` - Minimize admission of containers with allowPrivilegeEscalation
- `k8s-5.2.3-no-host-paths-admission.yaml` - Minimize admission of containers with allowedHostPaths
- `k8s-5.2.4-no-net-raw-capability.yaml` - Minimize admission of containers with NET_RAW capability
- `k8s-5.3.1-cni-network-policies.yaml` - Ensure CNI in use supports Network Policies
- `k8s-5.7.1-no-secrets-in-env.yaml` - Ensure secrets are not stored as environment variables
- `k8s-5.7.2-no-default-service-accounts.yaml` - Ensure default service accounts are not actively used
- `k8s-resource-limits-cpu-memory.yaml` - Ensure CPU and Memory limits are set

### Runtime Policies (runtime-*.yaml)
- `runtime-docker-1-container-escape.yaml` - Detect container escape attempts
- `runtime-docker-2-crypto-mining.yaml` - Detect cryptocurrency mining
- `runtime-docker-3-suspicious-network-tools.yaml` - Detect suspicious network tools
- `runtime-k8s-1-unauthorized-processes.yaml` - Detect unauthorized process execution
- `runtime-k8s-2-privilege-escalation.yaml` - Detect privilege escalation attempts
- `runtime-k8s-3-unauthorized-network.yaml` - Detect unauthorized network connections
- `runtime-k8s-4-readonly-fs-modifications.yaml` - Detect file system modifications in read-only areas
- `runtime-4-package-manager-usage.yaml` - Detect package manager usage
- `runtime-5-suspicious-downloads.yaml` - Detect suspicious file downloads
- `runtime-6-unauthorized-ports.yaml` - Detect unauthorized port binding

## Benefits of Clean Naming

1. **Readable**: Clear, descriptive names that immediately convey the policy purpose
2. **Short**: Filenames are 20-40 characters instead of 80-120 characters
3. **Organized**: Grouped by technology (docker, k8s, runtime) with consistent numbering
4. **Searchable**: Easy to find specific policies using simple keywords
5. **Maintainable**: Consistent format makes it easier to add new policies

## YAML Format

All policy files now follow the proper Kubernetes API structure required for StackRox/Red Hat Advanced Cluster Security (RHACS):

```yaml
apiVersion: config.stackrox.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: policy-name
  labels:
    app.kubernetes.io/name: cis-policy
    app.kubernetes.io/part-of: security-policies
spec:
  # Policy configuration details
  policyName: CIS Policy Name
  description: Policy description
  severity: HIGH_SEVERITY
  # ... other policy fields
```

## Usage

These YAML files can be imported directly into:
- StackRox/Red Hat Advanced Cluster Security (RHACS)
- Other security platforms that support CIS policy imports
- Kubernetes clusters with StackRox operator installed

## Original Source

These policies are based on the CIS Docker and Kubernetes Benchmarks, converted from JSON to YAML format with proper Kubernetes API structure for better readability and maintainability.
