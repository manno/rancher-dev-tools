# Simplified Build Scripts

Simple, readable scripts to build Rancher without dapper or the complex Makefile.

## Quick Start

```bash
# 1. Build the binaries
./hacks/build-binaries.sh

# 2. Build the Docker images
./hacks/build-image.sh

# Or with custom repo/tag:
REPO=myrepo TAG=test ./hacks/build-image.sh
```

## Scripts

### build-binaries.sh

Builds the Rancher server and agent binaries without dapper.

**What it does:**
- Builds `bin/rancher` (server binary)
- Builds `bin/agent` (agent binary)
- Downloads `bin/data.json` (KDM data)

**Environment variables:**
- `DEBUG=1` - Build with debug symbols
- `ARCH=arm64` - Build for specific architecture (default: amd64)
- `CATTLE_KDM_BRANCH=dev-v2.13` - KDM data branch (default: dev-v2.13)

**Example:**
```bash
# Standard build
./hacks/build-binaries.sh

# Debug build for ARM64
DEBUG=1 ARCH=arm64 ./hacks/build-binaries.sh
```

### build-image.sh

Builds the Rancher Docker images using the binaries from `build-binaries.sh`.

**What it does:**
- Builds `rancher/rancher:dev` (server image)
- Builds `rancher/rancher-agent:dev` (agent image)
- Reads versions from `build.yaml` automatically

**Environment variables:**
- `REPO=myrepo` - Docker repository (default: rancher)
- `TAG=test` - Docker tag (default: dev)
- `ARCH=arm64` - Architecture (default: amd64)

**Example:**
```bash
# Standard build
./hacks/build-image.sh

# Custom repo and tag
REPO=myregistry.com/rancher TAG=v2.13.0-test ./hacks/build-image.sh

# ARM64 build
ARCH=arm64 ./hacks/build-image.sh
```

### build-helm-chart.sh

Builds and packages the Rancher Helm chart.

**What it does:**
- Reads versions from `build.yaml` and git.
- Prepares the chart by replacing placeholders.
- Updates Helm dependencies.
- Packages the chart into `dist/artifacts/`.

**Example:**
```bash
# Build and package the chart
./hacks/build-helm-chart.sh
```

## Running Rancher

After building the images:

```bash
# Run Rancher server
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:dev

# Access at https://localhost
# Initial password is in the container logs:
docker logs <container-id> 2>&1 | grep "Bootstrap Password:"
```

## Why These Scripts?

The official build system uses:
- **Dapper** - Containerized build environment (requires Docker-in-Docker)
- **Complex Makefile** - Many layers of indirection
- **scripts/** directory - 40+ scripts with interdependencies

These simplified scripts:
- ✓ Run directly on your machine (no dapper needed)
- ✓ Are easy to read and understand (< 100 lines each)
- ✓ Do exactly what GitHub Actions does
- ✓ Can be easily modified for custom builds

## Differences from Official Build

These scripts skip:
- Containerized build environment (dapper)
- Code generation (`go generate`)
- Running tests
- Creating release artifacts

If you need those, use the official `make` targets.

## Troubleshooting

**Error: "Binaries not found"**
- Run `build-binaries.sh` before `build-image.sh`

**Error: "go: command not found"**
- Install Go 1.24+ from https://go.dev/dl/

**Error: "docker: command not found"**
- Install Docker from https://www.docker.com/get-started

**Build fails with missing dependencies**
- Run `go mod download` first
