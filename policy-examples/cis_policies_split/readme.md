# CIS Policy Files - Filename Mapping

This document maps the original long filenames to the new simplified, readable names.

## Docker Policies

| Original Filename | New Filename | Description |
|------------------|--------------|-------------|
| `docker_CIS-Docker-4.1_-_Ensure_image_is_not_running_as_root.json` | `docker-4.1-no-root-user.json` | Ensure image is not running as root |
| `docker_CIS-Docker-4.2_-_Ensure_that_containers_use_only_trusted_base_images.json` | `docker-4.2-trusted-base-images.json` | Ensure containers use only trusted base images |
| `docker_CIS-Docker-4.3_-_Ensure_unnecessary_packages_are_not_installed.json` | `docker-4.3-no-unnecessary-packages.json` | Ensure unnecessary packages are not installed |
| `docker_CIS-Docker-4.4_-_Ensure_images_are_scanned_and_rebuilt_to_include_security_patches.json` | `docker-4.4-image-scanning.json` | Ensure images are scanned and rebuilt for security patches |
| `docker_CIS-Docker-4.5_-_Ensure_Content_trust_for_Docker_is_Enabled.json` | `docker-4.5-content-trust.json` | Ensure Content trust for Docker is enabled |
| `docker_CIS-Docker-4.6_-_Ensure_HEALTHCHECK_instruction_has_been_added_to_container_image.json` | `docker-4.6-healthcheck.json` | Ensure HEALTHCHECK instruction is added to container image |
| `docker_CIS-Docker-4.7_-_Ensure_sensitive_host_system_directories_are_not_mounted.json` | `docker-4.7-no-sensitive-mounts.json` | Ensure sensitive host system directories are not mounted |
| `docker_CIS-Docker-5.1_-_Ensure_AppArmor_Profile_is_Enabled.json` | `docker-5.1-apparmor-profile.json` | Ensure AppArmor Profile is enabled |
| `docker_CIS-Docker-5.2_-_Ensure_SELinux_security_options_are_set_if_applicable.json` | `docker-5.2-selinux-options.json` | Ensure SELinux security options are set if applicable |
| `docker_CIS-Docker-5.7_-_Ensure_privileged_ports_are_not_mapped.json` | `docker-5.7-no-privileged-ports.json` | Ensure privileged ports are not mapped |
| `docker_CIS-Docker-5.8_-_Ensure_the_host's_user_namespaces_are_not_shared.json` | `docker-5.8-no-shared-user-namespaces.json` | Ensure host's user namespaces are not shared |
| `docker_CIS-Docker-5.9_-_Ensure_the_host's_network_namespace_is_not_shared.json` | `docker-5.9-no-shared-network-namespaces.json` | Ensure host's network namespace is not shared |
| `docker_CIS-Docker-5.10_-_Ensure_memory_usage_for_container_is_limited.json` | `docker-5.10-memory-limits.json` | Ensure memory usage for container is limited |
| `docker_CIS-Docker-5.11_-_Ensure_CPU_priority_is_set_appropriately_on_the_container.json` | `docker-5.11-cpu-priority.json` | Ensure CPU priority is set appropriately on the container |
| `docker_CIS-Docker-5.12_-_Ensure_the_container's_root_filesystem_is_mounted_as_read_only.json` | `docker-5.12-readonly-rootfs.json` | Ensure container's root filesystem is mounted as read-only |
| `docker_CIS-Docker-5.25_-_Ensure_container_is_restricted_from_acquiring_additional_privileges.json` | `docker-5.25-no-privilege-escalation.json` | Ensure container is restricted from acquiring additional privileges |

## Kubernetes Policies

| Original Filename | New Filename | Description |
|------------------|--------------|-------------|
| `k8s_CIS-K8s-5.1.1_-_Minimize_Privileged_Containers.json` | `k8s-5.1.1-no-privileged-containers.json` | Minimize privileged containers |
| `k8s_CIS-K8s-5.1.2_-_Minimize_hostNetwork_Usage.json` | `k8s-5.1.2-no-host-network.json` | Minimize hostNetwork usage |
| `k8s_CIS-K8s-5.1.3_-_Minimize_hostPID_and_hostIPC_Usage.json` | `k8s-5.1.3-no-host-pid-ipc.json` | Minimize hostPID and hostIPC usage |
| `k8s_CIS-K8s-5.1.4_-_Minimize_allowPrivilegeEscalation.json` | `k8s-5.1.4-no-privilege-escalation.json` | Minimize allowPrivilegeEscalation |
| `k8s_CIS-K8s-5.1.5_-_Minimize_Root_Containers.json` | `k8s-5.1.5-no-root-containers.json` | Minimize root containers |
| `k8s_CIS-K8s-5.1.6_-_Minimize_capabilities.json` | `k8s-5.1.6-minimize-capabilities.json` | Minimize capabilities |
| `k8s_CIS-K8s-5.2.1_-_Minimize_admission_of_containers_with_allowPrivilegeEscalation.json` | `k8s-5.2.1-no-privilege-escalation-admission.json` | Minimize admission of containers with allowPrivilegeEscalation |
| `k8s_CIS-K8s-5.2.3_-_Minimize_admission_of_containers_with_allowedHostPaths.json` | `k8s-5.2.3-no-host-paths-admission.json` | Minimize admission of containers with allowedHostPaths |
| `k8s_CIS-K8s-5.2.4_-_Minimize_admission_of_containers_with_NET_RAW_capability.json` | `k8s-5.2.4-no-net-raw-capability.json` | Minimize admission of containers with NET_RAW capability |
| `k8s_CIS-K8s-5.3.1_-_Ensure_CNI_in_use_supports_Network_Policies.json` | `k8s-5.3.1-cni-network-policies.json` | Ensure CNI in use supports Network Policies |
| `k8s_CIS-K8s-5.7.1_-_Ensure_that_secrets_are_not_stored_as_environment_variables.json` | `k8s-5.7.1-no-secrets-in-env.json` | Ensure secrets are not stored as environment variables |
| `k8s_CIS-K8s-5.7.2_-_Ensure_that_default_service_accounts_are_not_actively_used.json` | `k8s-5.7.2-no-default-service-accounts.json` | Ensure default service accounts are not actively used |
| `k8s_CIS-K8s-Resource-Limits_-_Ensure_CPU_and_Memory_limits_are_set.json` | `k8s-resource-limits-cpu-memory.json` | Ensure CPU and Memory limits are set |

## Runtime Policies

| Original Filename | New Filename | Description |
|------------------|--------------|-------------|
| `runtime_CIS-Docker-Runtime-1_-_Detect_Container_Escape_Attempts.json` | `runtime-docker-1-container-escape.json` | Detect container escape attempts |
| `runtime_CIS-Docker-Runtime-2_-_Detect_Cryptocurrency_Mining.json` | `runtime-docker-2-crypto-mining.json` | Detect cryptocurrency mining |
| `runtime_CIS-Docker-Runtime-3_-_Detect_Suspicious_Network_Tools.json` | `runtime-docker-3-suspicious-network-tools.json` | Detect suspicious network tools |
| `runtime_CIS-K8s-Runtime-1_-_Detect_Unauthorized_Process_Execution.json` | `runtime-k8s-1-unauthorized-processes.json` | Detect unauthorized process execution |
| `runtime_CIS-K8s-Runtime-2_-_Detect_Privilege_Escalation_Attempts.json` | `runtime-k8s-2-privilege-escalation.json` | Detect privilege escalation attempts |
| `runtime_CIS-K8s-Runtime-3_-_Detect_Unauthorized_Network_Connections.json` | `runtime-k8s-3-unauthorized-network.json` | Detect unauthorized network connections |
| `runtime_CIS-K8s-Runtime-4_-_Detect_File_System_Modifications_in_Read-Only_Areas.json` | `runtime-k8s-4-readonly-fs-modifications.json` | Detect file system modifications in read-only areas |
| `runtime_CIS-Runtime-4_-_Detect_Package_Manager_Usage.json` | `runtime-4-package-manager-usage.json` | Detect package manager usage |
| `runtime_CIS-Runtime-5_-_Detect_Suspicious_File_Downloads.json` | `runtime-5-suspicious-downloads.json` | Detect suspicious file downloads |
| `runtime_CIS-Runtime-6_-_Detect_Unauthorized_Port_Binding.json` | `runtime-6-unauthorized-ports.json` | Detect unauthorized port binding |

## Benefits of New Naming Convention

1. **Shorter**: Filenames are now 20-40 characters instead of 80-120 characters
2. **Readable**: Clear, descriptive names that are easy to understand
3. **Organized**: Grouped by category (docker, k8s, runtime) with consistent numbering
4. **Searchable**: Easy to find specific policies using simple keywords
5. **Maintainable**: Consistent format makes it easier to add new policies
