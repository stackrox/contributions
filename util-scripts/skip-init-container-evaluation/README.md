# Skip Init Container Evaluation

Starting in ACS 5.0, policies evaluate init containers by default. This script adds `skipContainerTypes: ["INIT"]` to all existing policies that don't already have an evaluation filter, preserving the pre-5.0 behavior where init containers were not evaluated.

## Usage

```bash
export ROX_ENDPOINT="central.example.com:443"
export ROX_API_TOKEN="your-api-token"

./skip-init-container-evaluation.sh
```

## Requirements

- ACS 5.0 or later
- `curl` and `jq` installed
- An API token with policy read/write permissions

## What it does

1. Checks that Central is running ACS 5.0+
2. Lists all policies and prompts for confirmation before making changes
3. For each policy without an existing evaluation filter, adds `skipContainerTypes: ["INIT"]`
4. Skips policies that already have a container type filter set
5. Skips build-only policies (container type filters are not applicable at build time)

## Policy-as-Code users

If you manage policies via SecurityPolicy CRDs and a GitOps workflow, update your policy manifests directly instead of running this script. Add the following to each policy spec:

```yaml
spec:
  # ... existing policy fields ...
  evaluationFilter:
    skipContainerTypes:
      - INIT
```
