# Jenkins CI

This directory contains the Jenkins pipeline for StryderX.

## Pipeline

`Jenkinsfile` runs the project inside the Docker image built from `stryderx_docker/Dockerfile`.

Stages:

1. `Lint` - runs `make lint`
2. `Build` - runs `make build`
3. `Test` - runs `make test`
4. `Docs` - runs `make docs` on `main`

## Agent Selection

The pipeline exposes an `AGENT` parameter:

- `StryderX-Core`
- `Linux`

The selected value is used as the Jenkins Docker agent label.

## Artifacts

The pipeline archives:

- `log/test_report.log`
- Doxygen HTML docs from `build/stryderx_hardware/docs/html/**` on `main`

JUnit results are collected from:

```text
build/**/test_results/**/*.xml
```

## Local Equivalent

Run the same checks locally with:

```sh
make lint
make build
make test
make report
```
