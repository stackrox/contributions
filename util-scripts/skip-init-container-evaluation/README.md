# Skip Init Container Evaluation

Starting in ACS 5.0, policies evaluate init containers by default. This script is a **one-time post-upgrade tool** that adds `skipContainerTypes: ["INIT"]` to all existing policies that don't already have an evaluation filter, preserving the pre-5.0 behavior where init containers were not evaluated.

This script is not intended to be run repeatedly or as a long-term maintenance tool.

## Usage

```bash
export ROX_ENDPOINT="central.example.com:443"
export ROX_API_TOKEN="your-api-token"

./skip-init-container-evaluation.sh
```

Each policy is presented for confirmation with options: `yes` (update this policy), `no` (skip this policy), or `all` (update this and all remaining policies without further prompts).

## Requirements

- ACS 5.0 or later
- `curl` and `jq` installed
- An API token with policy read/write permissions

## What it does

1. Checks that Central is running ACS 5.0+
2. Lists all policies and prompts for confirmation before making changes
3. For each applicable policy without an existing evaluation filter, adds `skipContainerTypes: ["INIT"]`
4. Skips policies that already have an evaluation filter
5. Skips build-only policies (container type filters are not applicable at build time)
6. Skips declarative (CRD-managed) policies
7. Skips audit log and node event policies (they don't evaluate containers)

## Policy-as-Code users

If you manage policies via SecurityPolicy CRDs and a GitOps workflow, update your policy manifests directly instead of running this script. Add the following to each policy spec:

```yaml
spec:
  # ... existing policy fields ...
  evaluationFilter:
    skipContainerTypes:
      - INIT
```
