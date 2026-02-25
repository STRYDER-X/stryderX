#!/bin/bash

# Stop on error to prevent broken builds
set -e

# --- HELP FUNCTIONS ---
show_help() {
    echo "Usage: ./generate_env.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this message"
    echo "  -r, --ros_distro    Provide ROS distro explicitly."
}

show_ros_help() {
    echo "Usage: ./generate_env.sh [-r|--ros_distro <distro>]"
    echo ""
    echo "Supported Distros:"
    echo "  - humble, iron, jazzy, rolling"
    echo ""
    echo "Examples:"
    echo "  $ ./generate_env.sh -r jazzy"
    echo "  $ ./generate_env.sh --ros_distro humble"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "-r" || "$1" == "--ros_distro" ]]; then
    ROS_DISTRO="$2"
    case "$ROS_DISTRO" in
        humble|iron|jazzy|rolling) 
            # It's valid, do nothing
            ;;
        *) 
            echo "❌ ERROR: Invalid ROS_DISTRO '$ROS_DISTRO'."
            show_ros_help
            exit 1 
            ;;
    esac
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
  humble|iron|jazzy|rolling|main) ;;
  *) TARGET="main" ;;
esac

PREFIX="$TARGET"

if [[ "$TARGET" == "main" ]]; then
    if [[ -z "$ROS_DISTRO" ]]; then
        echo "❌ ERROR: Branch is 'main' (or unknown schema)."
        echo "You must use the -r or --ros_distro flag to provide the distro"
        echo "manually."
        echo ""
        show_ros_help
        exit 1
    fi
else
    # Warn the user if they passed a flag that conflicts with the branch
    if [[ -n "$ROS_DISTRO" && "$ROS_DISTRO" != "$TARGET" ]]; then
        echo "⚠️  WARNING: You provided '-r $ROS_DISTRO', but your branch"
        echo "dictates '$TARGET'."
        echo "    Ignoring the flag and building for '$TARGET' based on the"
        echo "    branch name."
        echo "---------------------------------------"
    fi
    
    # Branch dictates the distro
    ROS_DISTRO="$TARGET"
fi

# Use explicit tags if available.
if git describe --tags --match "${PREFIX}-*" >/dev/null 2>&1; then
    TAG=$(git describe --tags --match "${PREFIX}-*")
else
    TAG="${PREFIX}-dev-${GIT_COMMIT}"
fi

echo "---------------------------------------"
echo "🤖  PROJECT:      robot-base-docker"
echo "---------------------------------------"
echo "🌿  Branch:       $GIT_BRANCH"
echo "🔧  ROS Distro:   $ROS_DISTRO"
echo "🔗  Commit:       $GIT_COMMIT"
echo "🏷️   Image Tag:    $TAG"
echo "---------------------------------------"

cat <<EOF > .env
APP_VERSION=$TAG
GIT_COMMIT=$GIT_COMMIT
BUILD_DATE=$DATE
ROS_DISTRO=$ROS_DISTRO
USER_UID=$(id -u 2>/dev/null || echo 1000)
USER_GID=$(id -g 2>/dev/null || echo 1000)
EOF

echo "✅ Environment configured in .env file."
echo "---------------------------------------"