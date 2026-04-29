#!/bin/sh

set -euxo pipefail

if [ $# -lt 1 ]; then
  chart=$(ls -1tr ./*.tgz 2>/dev/null | tail -1)
else
  chart=$1
fi

if [ -z "$chart" ] || [ ! -f "$chart" ]; then
  echo "Chart not found: ${chart:-no .tgz files in current directory}"
  exit 1
fi

echo "Installing chart: $chart"

public_hostname="${PUBLIC_HOSTNAME:-}"
rancherpassword="${RANCHER_PASSWORD-admin}"

if [ -z "${public_hostname}" ]; then
  until kubectl get service -n kube-system traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'; do sleep 3; done
  ip=$(kubectl get service -n kube-system traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  public_hostname="$ip.sslip.io"
fi

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.1/cert-manager.yaml
kubectl wait --for=condition=Available deployment --timeout=2m -n cert-manager --all

helm upgrade rancher $chart \
  --devel --install --wait \
  --create-namespace --namespace cattle-system \
  --set replicas=1 \
  --set "extraEnv[0].name=CATTLE_SERVER_URL" \
  --set "extraEnv[0].value=https://$public_hostname" \
  --set hostname="$public_hostname" \
  --set bootstrapPassword="$rancherpassword" \
  --set agentTLSMode=system-store \
  --set "rancherImageTag=dev"
