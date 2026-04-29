#!/bin/bash
# Description: Create the management cluster

set -euxo pipefail

name=${1-upstream}

# k3d version list k3s: https://hub.docker.com/r/rancher/k3s/tags
args=${K3D_ARGS- --network rancher --servers=1 -i docker.io/rancher/k3s:v1.33.1-k3s1}
unique_api_port=${unique_api_port-36443}
unique_tls_port=${unique_tls_port-443}

k3d cluster create "$name" \
  --servers 1 \
  --api-port "$unique_api_port" \
  -p "$unique_tls_port:443@server:0" \
  --k3s-arg '--tls-san=k3d-upstream-server-0@server:0' \
  $args
