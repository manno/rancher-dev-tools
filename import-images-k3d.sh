#!/bin/sh
set -euxo pipefail

name=${K3D_CLUSTER-upstream}
DS_CLUSTER_COUNT=${DS_CLUSTER_COUNT-1}

image="rancher/rancher:dev"
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^$image$"; then
  k3d image import "$image" -c "$name"
else
  echo "Image $image not found."
  exit 1
fi

image="rancher/rancher-agent:dev"
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^$image$"; then
  k3d image import "$image" -c "$name"
else
  echo "Image $image not found."
  exit 1
fi

for i in $(seq 1 "$DS_CLUSTER_COUNT"); do
  k3d image import rancher/rancher:dev rancher/rancher-agent:dev -c "downstream$i" || true
done
