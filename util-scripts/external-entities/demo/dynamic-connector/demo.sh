#!/usr/bin/env bash
set -eou pipefail

curl "http://127.0.0.1:8181/?action=open&ip=8.8.8.8&port=53"

# Check network graph

# Lock baseline

curl "http://127.0.0.1:8181/?action=open&ip=142.250.72.238&port=80"

# Check network graph and violations

curl "http://127.0.0.1:8181/?action=open&ip=1.1.1.1&port=53"

# Check network graph
