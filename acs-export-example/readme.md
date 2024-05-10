# ACS/StackRox Export CLI

![Made with VHS](https://vhs.charm.sh/vhs-6oVYwxgou22QgkIgZackdK.gif)

A CLI that generates a CVE report based on the ACS export APIs.

```
$ ./acs-export-example -h
CLI to browse data pulled from ACS (Advanced Cluster Security) (i.e. StackRox).

Usage:
  acs-export-example [flags]

Flags:
  -c, --cluster string       Cluster client-side filter.
  -t, --filter-type string   Where to do the param-based filtering. Available options: [client, server] (default "client")
  -f, --fixable string       Filter on whether a cve is fixable.  Available options: [true, false, ""].
  -h, --help                 help for acs-export-example
  -i, --image string         Image name client-side filter.
  -n, --namespace string     Namespace client-side filter.
  -o, --output string        Output format.  Available options: [table, csv] (default "table")
  -q, --query string         Pass a query string to the server. Incompatible with --filter-type=server
  -s, --stats                Print stats about the export
  -v, --vuln string          Vulnerability client-side filter.
```

## Setup

Currently the only way to configure the Central endpoint is to set these two environment variables:

    export ROX_ENDPOINT=https://central.stackrox.com
    export ROX_API_TOKEN=eyJh... # base64-encoded JWT

## Output Formats

Print a table to the console with all reported vulnerabilities:

    $ ./acs-export-example 

Output in CSV format instead:

    $ ./acs-export-example -o csv

## Filters

Filter by cluster:

    $ ./acs-export-example -c acs-stage-cluster

Filter by cluster and namespace:

    $ ./acs-export-example -c acs-stage-cluster -n stackrox

Filter by CVE/vulnerability name:

    $ ./acs-export-example -v CVE-2021-0000

Filter by image name:

    $ ./acs-export-example -i quay.io/kylape/my-image-repo

Filter on whether a vulnerability is considered fixable or not:

    $ ./acs-export-example -f true  # Only output fixable vulns

The above filters are performed on the client side by default.
Use the `--filter-type=server` option to instead build a query string to have the filters executed on the server:

    $ ./acs-export-example -i quay.io/kylape/my-image-repo -t server

If you'd rather build the query string for the server yourself:

    $ ./acs-export-example -q "CLUSTER:acs-stage-cluster+NAMESPACE:stackrox+CVE:r/CVE-2021-0000"

## Stats

The `--stats` option prints various timings and counts that may be interesting to use for performance analysis:

```
$ ./acs-export-example -o csv -s > export.csv
Fetching deployments
Fetching images
Durations:
  Connect: 295.686µs
  Deployment Export: 611.136684ms
  Image Export: 4.048604959s
  Deployment Filtering: 47.291µs
  Image Filtering: 2.547318ms

Counts:
  Deployments: 444
  Images: 375
  Filtered Deployments: 444
  Filtered Images: 353
```

## Building

```
go build
```
