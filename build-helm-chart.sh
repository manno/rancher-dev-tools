#!/bin/bash
set -e

echo "Building Rancher Helm Chart..."

# --- Versioning ---
echo "Determining versions..."
# Get versions from git
COMMIT=$(git rev-parse --short HEAD)
if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
    DIRTY="-dirty"
fi
# Create a valid SemVer for development builds
VERSION="0.0.0-${COMMIT}${DIRTY}"

# Read versions from build.yaml
WEBHOOK_VERSION=$(grep 'webhookVersion:' build.yaml | awk '{print $2}')
DEFAULT_SHELL_VERSION=$(grep 'defaultShellVersion:' build.yaml | awk '{print $2}')

# Split shell version into name and tag
SHELL_IMAGE_NAME=$(echo "${DEFAULT_SHELL_VERSION}" | cut -d ":" -f 1)
SHELL_IMAGE_TAG=$(echo "${DEFAULT_SHELL_VERSION}" | cut -d ":" -f 2)

echo "  Version: ${VERSION}"
echo "  Webhook Version: ${WEBHOOK_VERSION}"
echo "  Shell Version: ${DEFAULT_SHELL_VERSION}"


# --- Chart Build ---
BUILD_DIR="build/chart"
CHART_DIR="${BUILD_DIR}/rancher"
SOURCE_CHART_DIR="chart"

# 1. Prepare build directory
echo "Preparing build directory..."
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cp -r ${SOURCE_CHART_DIR} ${CHART_DIR}

# 2. Replace placeholders
echo "Replacing placeholders in Chart.yaml and values.yaml..."
# Use a temp file for sed to avoid issues with -i on different platforms
sed_temp_file="${CHART_DIR}/sed.tmp"

# Chart.yaml replacements
sed -e "s/%VERSION%/${VERSION}/g" \
    -e "s/%APP_VERSION%/${VERSION}/g" \
    -e "s/%WEBHOOK_VERSION%/${WEBHOOK_VERSION}/g" \
    "${CHART_DIR}/Chart.yaml" > "${sed_temp_file}" && mv "${sed_temp_file}" "${CHART_DIR}/Chart.yaml"

# values.yaml replacements
sed -e "s@%POST_DELETE_IMAGE_NAME%@${SHELL_IMAGE_NAME}@g" \
    -e "s/%POST_DELETE_IMAGE_TAG%/${SHELL_IMAGE_TAG}/g" \
    -e "s@%PRE_UPGRADE_IMAGE_NAME%@${SHELL_IMAGE_NAME}@g" \
    -e "s/%PRE_UPGRADE_IMAGE_TAG%/${SHELL_IMAGE_TAG}/g" \
    "${CHART_DIR}/values.yaml" > "${sed_temp_file}" && mv "${sed_temp_file}" "${CHART_DIR}/values.yaml"


# 3. Update dependencies
echo "Updating helm dependencies..."
helm dependency update ${CHART_DIR}


# --- Chart Package ---
PACKAGE_DIR="dist/artifacts"

# 4. Package chart
echo "Packaging chart..."
mkdir -p ${PACKAGE_DIR}
helm package ${CHART_DIR} -d ${PACKAGE_DIR}

echo "Helm chart packaged successfully in ${PACKAGE_DIR}/"
ls -ltr ${PACKAGE_DIR}/*
