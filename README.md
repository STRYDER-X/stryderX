# StryderX

![ROS 2](https://img.shields.io/badge/ROS%202-Humble-blue)
[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

**StryderX** is the ROS 2 Humble workspace for the StryderX RC robot platform. This repository brings the robot packages, vendor dependencies, and Docker runtime together so the stack can be built, tested, and run from one workspace.

Package-specific behavior, nodes, launch files, parameters, and interfaces are documented in each package README.

## Workspace Layout

| Path | Purpose |
| :--- | :--- |
| `src/stryderx_bringup` | ROS 2 launch and runtime configuration package. |
| `src/stryderx_hardware` | ROS 2 hardware-facing node package. |
| `vendor/rosmaster_lib_v3` | Vendor library used by the robot controller nodes. |
| `stryderx_docker` | Docker image, Compose services, and setup scripts. |
| `jenkins` | Jenkins pipeline and CI documentation. |
| `Makefile` | Workspace entry point for Docker, build, lint, test, docs, and cleanup tasks. |

## Package Docs

- [`src/stryderx_bringup/README.md`](src/stryderx_bringup/README.md): launch files, bringup commands, and runtime configs.
- [`src/stryderx_hardware/README.md`](src/stryderx_hardware/README.md): hardware nodes, executables, ROS interfaces, and parameters.

## Requirements

- Docker Engine 20.10+ with Docker Compose V2.
- GNU Make.
- Git with submodule support.
- Optional: `pre-commit` on the host for local commit hooks.
- Robot hardware when using the hardware profile:
  - USB camera at `/dev/video0`.
  - USB serial controller at `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0`.
  - Joystick input devices under `/dev/input`.

## Quick Start

Clone the workspace with submodules:

```bash
git clone --recursive https://github.com/jrendon102/stryderX.git
cd stryderX
```

Generate the local Docker environment file:

```bash
make env
```

Start the development container and open a shell:

```bash
make up
make shell
```

Inside the container, build and verify the workspace:

```bash
make gate
```

`make gate` runs setup, lint, build, test, and report generation.

## Robot Runtime

Use the hardware profile on the robot host. This profile adds access to camera, USB serial, and joystick input devices.

From the host:

```bash
make up hardware
make shell hardware
```

Inside the hardware container:

```bash
make build
source install/setup.bash
ros2 launch stryderx_bringup hardware.launch.py
```

See the bringup package README for individual subsystem launch commands and configuration details.

## Common Commands

```bash
make help
make env
make up
make up hardware
make shell
make shell hardware
make build
make lint
make test
make report
make view
make docs
make clean
make purge
make down
```

## CI

Jenkins pipeline configuration lives in [`jenkins/`](jenkins/).

The CI pipeline runs the same core checks as local development:

```bash
make lint
make build
make test
make report
```

On `main`, Jenkins also generates and archives Doxygen docs with:

```bash
make docs
```

See [`jenkins/README.md`](jenkins/README.md) for pipeline details, artifacts, and common CI failure notes.

## Development

Run the normal workspace quality gate before pushing:

```bash
make gate
```

Generate Doxygen docs for packages that provide a `docs` target:

```bash
make docs
```

Branches should follow:

```text
type/distro/description-issue#
```

Example:

```text
feat/humble/camera-server-logic-102
```

## Git Authentication In Containers

The development container does not include your host SSH keys. If pushing from inside the container, use an HTTPS remote:

```bash
git remote set-url origin https://github.com/STRYDER-X/stryderX.git
git remote -v
```

For submodules, sync URLs after changing the main remote:

```bash
git submodule sync --recursive
```

## Maintainer

- Julian A. Rendon
- julianrendon514@gmail.com
