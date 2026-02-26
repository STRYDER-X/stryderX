FROM jrendon514/robot-base-docker:humble-v0.2.0

# Workspace for StryderX ROS2 packages
RUN mkdir -p /home/rpi/stryderx && chown -R rpi:rpi /home/rpi/stryderx

ARG APP_VERSION=DEV
ARG GIT_COMMIT_HASH="unknown" 
ARG BUILD_DATE="unknown"

LABEL org.opencontainers.image.authors="Julian A. Rendon" \
    org.opencontainers.image.source="https://github.com/STRYDER-X/stryderX" \
    org.opencontainers.image.description="Docker image for STRYDER-X ROS2 Humble" \
    org.opencontainers.image.licenses="GPLv3" \
    org.opencontainers.image.version="${APP_VERSION}" \
    org.opencontainers.image.revision="${GIT_COMMIT_HASH}" \
    org.opencontainers.image.created="${BUILD_DATE}"

CMD ["/bin/bash"]