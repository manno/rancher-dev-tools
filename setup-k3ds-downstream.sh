#!/bin/bash
# Description: Create n downstream clusters

set -euxo pipefail

name="downstream"
args="--network rancher --servers=1 -i docker.io/rancher/k3s:v1.33.1-k3s1"

DS_CLUSTER_COUNT=${DS_CLUSTER_COUNT-1}

for i in $(seq 1 "$DS_CLUSTER_COUNT"); do
  k3d cluster create "$name$i" \
    --servers 1 \
    --api-port $((36443 + i)) \
    -p "$((4080 + (1000 * i))):80@server:0" \
    -p "$((3443 + i)):443@server:0" \
    --k3s-arg "--tls-san=k3d-$name$i-server-0@server:0" \
    $args
done
