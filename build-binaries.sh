#!/usr/bin/env bash
# Simple script to build Rancher binaries without dapper
set -e

cd "$(dirname "$0")/.."

# Get version info
DIRTY=""
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    DIRTY="-dirty"
fi

COMMIT=$(git rev-parse --short HEAD)
GIT_TAG=${GIT_TAG:-$(git tag -l --contains HEAD | head -n 1)}

if [[ -z "$DIRTY" && -n "$GIT_TAG" ]]; then
    VERSION=$GIT_TAG
else
    VERSION="${COMMIT}${DIRTY}"
fi

# Architecture
ARCH=${ARCH:-amd64}

# Create output directory
mkdir -p bin

echo "Building Rancher binaries..."
echo "  Version: $VERSION"
echo "  Commit:  $COMMIT"
echo "  Arch:    $ARCH"

# Build server
echo "Building server binary..."
CGO_ENABLED=0 go build -tags k8s \
    -gcflags="all=-N -l" \
    -ldflags "-X github.com/rancher/rancher/pkg/version.Version=$VERSION -X github.com/rancher/rancher/pkg/version.GitCommit=$COMMIT" \
    -o bin/rancher

# Build agent
echo "Building agent binary..."
CGO_ENABLED=0 go build -tags k8s \
    -gcflags="all=-N -l" \
    -ldflags "-X main.VERSION=$VERSION" \
    -o bin/agent \
    ./cmd/agent

# Download KDM data
CATTLE_KDM_BRANCH=${CATTLE_KDM_BRANCH:-dev-v2.13}
echo "Downloading KDM data from branch: $CATTLE_KDM_BRANCH"
curl -sLf "https://releases.rancher.com/kontainer-driver-metadata/${CATTLE_KDM_BRANCH}/data.json" > bin/data.json

echo ""
echo "✓ Binaries built successfully:"
echo "  - bin/rancher"
echo "  - bin/agent"
echo "  - bin/data.json"
