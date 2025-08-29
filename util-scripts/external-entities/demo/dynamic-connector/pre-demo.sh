#!/usr/bin/env bash
set -eou pipefail

kubectl delete ns qa || true

kubectl create ns qa

kubectl create -f dynamic-connector.yml

sleep 15

kubectl -n qa port-forward deploy/dynamic-connector 8181 > /dev/null 2>&1 &
