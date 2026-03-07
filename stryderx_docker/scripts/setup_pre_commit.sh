#!/bin/bash
PROJECT_NAME=StryderX

CONFIG_DIRS=$(find . -maxdepth 4 -name ".pre-commit-config.yaml" \
    -not -path "*/build/*" \
    -not -path "*/install/*" \
    -not -path "*/log/*" \
    -exec dirname {} \;)

echo "[$PROJECT_NAME] Found $(echo "$CONFIG_DIRS" | wc -l) pre-commit configurations."

for dir in $CONFIG_DIRS; do
    echo "[$PROJECT_NAME] Installing hooks in: $dir"
    cd "$dir" && pre-commit install
    pre-commit install-hooks
    cd - > /dev/null || exit
done

echo "[$PROJECT_NAME] Workspace protection is now active."
