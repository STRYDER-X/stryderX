# StryderX

![ROS 2](https://img.shields.io/badge/ROS%202-Humble-blue)
[![License](https://img.shields.io/badge/license-GNU%20GPL-blue.svg)](LICENSE)

**StryderX** is a ROS 2 Humble workspace for an RC robot platform. The repo brings together the robot hardware package, third-party low-level drivers, and a Docker-based development/runtime environment for running the stack on the robot or on a development machine.

## Project Layout

- `src/stryderx_hardware`: ROS 2 hardware abstraction package.
- `src/stryderx_hardware/third_party`: Driver libraries used by the hardware package.
- `stryderx_docker`: Docker image, Compose services, and environment setup scripts.
- `Makefile`: Main entry point for building, testing, and starting containers.

## Architecture

StryderX uses a two-layer hardware interface:

1. **Low-level drivers** are plain C++ or Python libraries with no ROS middleware dependency.
2. **ROS 2 wrappers** expose those drivers as nodes, topics, and services.

Current robot-facing nodes include:

- `camera_server_node`: Camera stream and luminosity service interface.
- `drive_controller`: Joystick throttle control.
- `steering_controller`: Joystick steering control.
- `joy_node`: ROS 2 joystick input node from `ros-humble-joy`.

## Requirements

- Docker Engine 20.10+ with Docker Compose V2.
- GNU Make.
- Git with submodule support.
- Optional: `pre-commit` on the host for local commit hooks.
- Robot hardware: Linux host such as Raspberry Pi 4B, USB camera, USB serial controller, and joystick input device.

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

Start the development container:

```bash
make up
make shell
```

Inside the container, build and verify the workspace:

```bash
make gate
```

`make gate` runs setup, lint, build, test, and report generation.

## Start The Robot

Use the hardware profile when running on the robot host. This profile adds camera, USB serial, and `/dev/input/eventX` access for ROS joystick input.

From the host:

```bash
make up hardware
make shell hardware
```

Inside the hardware container:

```bash
make build
source install/setup.bash
```

Start joystick input in one shell:

```bash
ros2 run joy joy_node
```

Start the drive and steering controllers in separate shells:

```bash
ros2 run stryderx_hardware drive_controller
```

```bash
ros2 run stryderx_hardware steering_controller
```

Start the camera server when camera streaming is needed:

```bash
ros2 run stryderx_hardware camera_server_node
```

The hardware container expects these host devices:

- `/dev/video0` for the camera.
- `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0` for the serial controller, mapped to `/dev/myserial`.
- `/dev/input/eventX` devices for joystick input, mounted through `/dev/input`.

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
make down
```

## Camera Server

After building and sourcing the workspace, run:

```bash
ros2 run stryderx_hardware camera_server_node
```

Main interfaces:

| Interface | Type | Description |
| :--- | :--- | :--- |
| `~/camera/image/compressed` | `sensor_msgs/msg/CompressedImage` | Compressed camera stream. |
| `~/luminosity_value` | `std_msgs/msg/Float32` | Current light level. |
| `~/start_streaming` | `std_srvs/srv/Trigger` | Starts or resumes streaming. |
| `~/pause_streaming` | `std_srvs/srv/Trigger` | Pauses streaming. |
| `~/shutdown_server` | `std_srvs/srv/Trigger` | Releases camera hardware and stops the server. |

## Development

Install hooks if `pre-commit` is available on the host:

```bash
pre-commit install
```

Run the normal quality gate before pushing:

```bash
make gate
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

## Author

- Julian A. Rendon
- julianrendon514@gmail.com
