# Raspi Cross

> Cross-compile for Raspberry Pi with Docker.

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/rolandjitsu/raspi-cross/test.yml?branch=main&label=tests&style=flat-square)](https://github.com/rolandjitsu/raspi-cross/actions?query=workflow%3ATest)

## Prerequisites

Install the following tools:

- [Docker](https://docs.docker.com/engine) >= `20.10.0`
- [buildx](https://github.com/docker/buildx#installing) >= `v0.8.0`

## Setup Docker

Create a Docker builder instance if you don't already have one:

```bash
docker buildx create --name my-builder --driver docker-container --use
```

Then inspect and bootstrap it:

```bash
docker buildx inspect --bootstrap
```

## Compile

### Using Docker Buildx Bake (Recommended)

To compile both the `hello` and `hello-pi` binaries into `./bin`:

```bash
docker buildx bake
```

To compile only `hello`:

```bash
docker buildx bake hello
```

To compile only `hello-pi`:

```bash
docker buildx bake hello-pi
```

To bust the cache, add the `--no-cache` flag:

```bash
docker buildx bake --no-cache
```

### Using Docker Buildx directly

To compile the binaries with Buildx directly:

```bash
docker buildx build -f Dockerfile -o type=local,dest=./bin .
```

## Base Images

If you want to build or inspect the base cross-compilation images:

```bash
# Prepare the base cross-compilation image
docker buildx bake cross-base

# Prepare the base image with Raspberry Pi userland and WiringPi
docker buildx bake cross-pi
```

## Verifying Binaries

On Linux systems with QEMU user emulation installed (`qemu-user` and `libc6-dev-armhf-cross`):

```bash
# Test hello
qemu-arm -L /usr/arm-linux-gnueabihf/ ./bin/hello

# Test hello-pi
qemu-arm -L /usr/arm-linux-gnueabihf/ ./bin/hello-pi
```

## Learning Material

- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [Getting started with Docker for ARM on Linux](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
