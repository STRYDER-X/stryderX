# StryderX

![ROS 2](https://img.shields.io/badge/ROS%202-Humble-blue)
[![License](https://img.shields.io/badge/license-GNU%20GPL-blue.svg)](LICENSE)

**StryderX** is a modular RC robot platform designed for both autonomous and manual navigation. This repository serves as the main workspace, integrating hardware abstraction layers, simulation environments, and high-level control logic.

## Key Features

*   **Modular Architecture**: Decoupled hardware abstraction, control, and perception layers.
*   **Hardware Abstraction Layer (HAL)**: Robust interface for sensors and actuators, including a high-performance Camera Server.
*   **Dockerized Workflow**: Full containerization support for consistent development and deployment across different machines.
*   **ROS 2 Native**: Built on ROS 2 (Humble) for real-time communication and introspection.

## System Architecture

Following the **Two-Layer Hardware Interface**:

1. **Low-Level Drivers**: Pure C++/Python libraries with zero middleware dependencies.
2. **High-Level Wrappers**: ROS 2 nodes that bridge the libraries into the ROS ecosystem.

### Key Modules

- **`stryderx_hardware`**: The Hardware Abstraction Layer (HAL).
- **`stryderx_docker`**: Infrastructure as Code (IaC).

### Prerequisites

- **Docker Enginer** (20.10+) & **Docker Compose V2**
- **GNU Make**
- **pre-commit**: (Recommended) Install locally via pip install pre-commit to ensure hooks run during host-side commits.
- **Hardware**: Raspberry Pi 4B (Optimized) or standard x86/ARM64 Linux

## Quick Start

1. **Clone the Repository**

   Clone recursively to ensure all submodules are initialized. Then enter the worksapce.
   ```bash
   git clone --recursive https://github.com/jrendon102/stryderX.git .
   cd stryderX
   ```

2. **Initialize Environment**

   Generate the local `.env` file:
   ```bash
   make env

   # Installs hooks locally if pre-commit is on host
   pre-commit install
   ```

3. **Build & Launch**

    Start the Docker stack and enter the container:

    ```bash
    # Start Docker enironment
    make up
    ```

    ```bash
    # Enter the shell and source
    make shell
    ```

    Once inside container you should be placed inside the `stryderx` workspace.
    From there you can runthe following command to start the entire build process:
    ```bash
    make gate
    ```
    This will run the full pipeline: Setup -> Lint -> Build -> Test -> Report
> [!NOTE]
> To see the full list of targets and their descriptions you can simple run `make`.

## Usage

> [!NOTE]
> This project is currently a **Work in Progress**. While new feature are being implemented,
> you can run the core camera server node to verify that the hardware interface.

### Running Hardware Nodes
To launch the hardware abstraction layer (e.g., the camera server):

```bash
# Source the workspace
source install/setup.bash

ros2 run stryderx_hardware camera_server_node
```

## Contributing

Contribution are welcomed! To maintain a standard of code quiality and compatibility, please adhere to the following guidelines.

### Git & Branching Strategy

To keep things organized and ensure long-term compatabilitiy, I used **Distro Silos** for ROS 2 versions
(like hunble, jazzy, iron). This helps isolate changes for specific ROS 2 distributions.

### Branch Naming Convention:

Branches are named with the following convention: `type/distro/description-issue#`

- **Types**: `feat/`, `fix`, `refactor`, `doc`, `test`.
- **Example**: `feat/humble/camera-server-logic-102`.

### Quality Control

- **Workspace Protection**: Automated via `pre-commit` hooks. Ensure you run `make lint` before pushing.
> [!IMPORTANT]
> ***It is recommended that you commit from inside the container or installing `pre-commit` locally***

## Troubleshooting

The development container does not include SSH keys. More than likely when trying to push changes, **when inside the contianer**, to the remote repo errors will occur. To fix this you should updated the remote URL to HTTPS.
```bash
# Update remote URL to HTTPS
git remote set-url https://github.com/STRYDER-X/stryderX.git

# Verify the change
git remote -v
```

For submodules, run `git submodule sync` after updating the main repository's remote.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Author & Maintainer

- **Julian A. Rendon**
- Email: julianrendon514@gmail.com
