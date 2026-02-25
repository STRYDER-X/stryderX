#!/bin/bash

# Stop on error to prevent broken builds
set -e

ROS_DISTRO="humble"
TOP_LVL_DIR=$(pwd)/../

# --- HELP FUNCTIONS ---
show_help() {
    echo "Usage: ./generate_env.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this message"
    echo "  -r, --ros_distro    Provide ROS distro explicitly."
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Extract the target distro from branch names like 'feat/humble/fix'
if [[ "$GIT_BRANCH" == *"/"* ]]; then
    TARGET=$(echo "$GIT_BRANCH" | cut -d'/' -f2)
else
    TARGET="$GIT_BRANCH"
fi

# Sanitize target: default to 'main' for non-distro branches (e.g. 'doc/update')
case "$TARGET" in
  humble|iron|jazzy|rolling) ;;
  *) TARGET=$ROS_DISTRO ;;
esac

# Use explicit tags if available.
if git describe --tags --match "${TARGET}-*" >/dev/null 2>&1; then
    TAG=$(git describe --tags --match "${TARGET}-*")
else
    TAG="${TARGET}-dev-${GIT_COMMIT}"
fi

echo "---------------------------------------"
echo "🤖  PROJECT:      robot-base-docker"
echo "---------------------------------------"
echo "🌿  Branch:       $GIT_BRANCH"
echo "🔧  ROS Distro:   $ROS_DISTRO"
echo "🔗  Commit:       $GIT_COMMIT"
echo "🏷️   Image Tag:    $TAG"
echo "---------------------------------------"

cat <<EOF > $TOP_LVL_DIR/.env
APP_VERSION=$TAG
GIT_COMMIT=$GIT_COMMIT
BUILD_DATE=$DATE
ROS_DISTRO=$ROS_DISTRO
USER_UID=$(id -u 2>/dev/null || echo 1000)
USER_GID=$(id -g 2>/dev/null || echo 1000)
EOF

echo "✅ Environment configured in .env file."
echo "---------------------------------------"