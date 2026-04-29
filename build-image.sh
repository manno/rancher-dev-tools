#!/usr/bin/env bash
# Simple script to build Rancher Docker images without dapper
set -e

cd "$(dirname "$0")/.."

# Configuration
REPO=${REPO:-rancher}
TAG=${TAG:-dev}
ARCH=${ARCH:-amd64}
IMAGE_REPO=${IMAGE_REPO:-$REPO}

# Read versions from build.yaml
WEBHOOK_VERSION=$(grep -m1 'webhookVersion' build.yaml | awk '{print $2}')
REMOTEDIALER_VERSION=$(grep -m1 'remoteDialerProxyVersion' build.yaml | awk '{print $2}')
PROVISIONING_CAPI_VERSION=$(grep -m1 'provisioningCAPIVersion' build.yaml | awk '{print $2}')
TURTLES_VERSION=$(grep -m1 'turtlesVersion' build.yaml | awk '{print $2}')
CSP_ADAPTER_VERSION=$(grep -m1 'cspAdapterMinVersion' build.yaml | awk '{print $2}')
FLEET_VERSION=$(grep -m1 'fleetVersion' build.yaml | awk '{print $2}')

echo "Building Rancher Docker images..."
echo "  Repo: $REPO"
echo "  Tag:  $TAG"
echo "  Arch: $ARCH"
echo ""

# Check if binaries exist
if [ ! -f bin/rancher ] || [ ! -f bin/agent ] || [ ! -f bin/data.json ]; then
    echo "Error: Binaries not found in bin/ directory"
    echo "Run ./hacks/build-binaries.sh first"
    exit 1
fi

# Build server image
echo "Building server image: ${REPO}/rancher:${TAG}"
docker build \
    --build-arg VERSION="${TAG}" \
    --build-arg ARCH="${ARCH}" \
    --build-arg IMAGE_REPO="${IMAGE_REPO}" \
    --build-arg CHART_DEFAULT_BRANCH="dev-v2.13" \
    --build-arg CATTLE_RANCHER_WEBHOOK_VERSION="${WEBHOOK_VERSION}" \
    --build-arg CATTLE_REMOTEDIALER_PROXY_VERSION="${REMOTEDIALER_VERSION}" \
    --build-arg CATTLE_RANCHER_PROVISIONING_CAPI_VERSION="${PROVISIONING_CAPI_VERSION}" \
    --build-arg CATTLE_RANCHER_TURTLES_VERSION="${TURTLES_VERSION}" \
    --build-arg CATTLE_CSP_ADAPTER_MIN_VERSION="${CSP_ADAPTER_VERSION}" \
    --build-arg CATTLE_FLEET_VERSION="${FLEET_VERSION}" \
    --target server \
    -t "${REPO}/rancher:${TAG}" \
    -f ./package/Dockerfile \
    .

echo ""
echo "Building agent image: ${REPO}/rancher-agent:${TAG}"
docker build \
    --build-arg VERSION="${TAG}" \
    --build-arg ARCH="${ARCH}" \
    --build-arg RANCHER_TAG="${TAG}" \
    --build-arg RANCHER_REPO="${REPO}" \
    --build-arg CATTLE_RANCHER_WEBHOOK_VERSION="${WEBHOOK_VERSION}" \
    --build-arg CATTLE_RANCHER_PROVISIONING_CAPI_VERSION="${PROVISIONING_CAPI_VERSION}" \
    --build-arg CATTLE_RANCHER_TURTLES_VERSION="${TURTLES_VERSION}" \
    --target agent \
    -t "${REPO}/rancher-agent:${TAG}" \
    -f ./package/Dockerfile \
    .

echo ""
echo "✓ Images built successfully:"
echo "  - ${REPO}/rancher:${TAG}"
echo "  - ${REPO}/rancher-agent:${TAG}"
