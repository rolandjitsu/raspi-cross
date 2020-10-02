# Raspi Cross
> Cross-compile for Raspberry Pi with Docker.

## Prerequisites
Install the following tools:
* [Docker](https://docs.docker.com/engine) >= `19.03.13`
* [buildx](https://github.com/docker/buildx#installing) >= `v0.4.1`

## Setup Docker
Check current builder instances:
```bash
docker buildx ls
```

If you see an instance that uses the `docker` driver, switch to it (it's usually the `default`):
```
docker buildx use <instance name>
```

Otherwise, create a builder:
```bash
docker buildx create --name my-builder --driver docker --use
```
**NOTE**: You cannot create more than one instance using the `docker` driver.

Then inspect and bootstrap it:
```bash
docker buildx inspect --bootstrap
```

## Setup Base Images
Prepare the base cross-compilation image:
```bash
docker buildx build -f Dockerfile.cross --tag cross-stretch .
```
**NOTE**: By default, the image is going to be available to use on the host as `cross-stretch`. If `docker images` doesn't show it, add the `--load` flag when building.

*P.S.* To bust the cache, use `--no-cache`.

Prepare the base image w/ some common libs usually available on the Pi:
```bash
docker buildx build -f Dockerfile.cross-pi --tag cross-pi .
```

## Compile
Compile the `hello` binary:
```bash
docker buildx build -f Dockerfile.hello -o type=local,dest=./bin .
```

Compile the `hello-pi` binary:
```bash
docker buildx build -f Dockerfile.hello-pi -o type=local,dest=./bin .
```

## Bake
To make things easier, you can use the [bake](https://github.com/docker/buildx#buildx-bake-options-target) command.

To setup the base image:
```bash
docker buildx bake cross-stretch
```

To setup the base image w/ goodies:
```bash
docker buildx bake cross-pi
```

To compile the binaries:
```bash
docker buildx bake
```

*P.S.* To bust the cache, you can use `--no-cache`.

## Learning Material
* [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
* [Getting started with Docker for ARM on Linux](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/)
* [Leverage multi-CPU Architectures](https://docs.docker.com/docker-for-mac/multi-arch/)
* [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
