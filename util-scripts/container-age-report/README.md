# Container age report

This read-only script lists currently running container instances in StackRox Central that have been running for at least 30 days. It queries all pods visible to the API token across connected clusters and can print a command-line table or write CSV or HTML.

## Requirements

- Bash
- `curl`
- `jq`
- Python 3
- A StackRox API token with permission to view deployments and their pods

## Usage

```bash
./stackrox-container-age-report.sh \
  --central https://central.example.com \
  --token-file "$HOME/.rox-token" \
  --html \
  --output container-age-report.html
```

Use `--format text` for the default command-line table or `--csv` to write CSV. For example:

```bash
./stackrox-container-age-report.sh --central https://central.example.com \
  --token-file "$HOME/.rox-token" --csv --output container-age-report.csv
```

The script also accepts `ROX_CENTRAL_URL` and `ROX_API_TOKEN_FILE` environment variables. Tokens are read from a file or environment variable, not a command-line argument. `--insecure` disables TLS certificate verification and should only be used when necessary.

## Age calculation

The report uses the start timestamp for each current live container instance, rather than pod or deployment creation time. It measures age at the time the script starts, rounds to the nearest whole day, and groups results into 30–59, 60–90, and over 90 days. A container restart resets its age; replacing pods during a rollout gives the new containers new start times.

The HTML groups are collapsed initially. The Labels column combines deployment and pod-template labels, omits the `revision` label, renders labels with value `true` as the key alone, and wraps long label lists within the cell.
