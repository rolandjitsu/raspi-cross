# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=bookworm-slim
FROM debian:${DEBIAN_VERSION} AS cross-base

ARG GNU_HOST=arm-linux-gnueabihf
ENV GNU_HOST=${GNU_HOST}
ENV C_COMPILER_ARM_LINUX=${GNU_HOST}-gcc
ENV CXX_COMPILER_ARM_LINUX=${GNU_HOST}-g++

ENV CROSS_INSTALL_PREFIX=/usr/${GNU_HOST}
ENV CROSS_TOOLCHAIN=/usr/local/share/cmake/arm.toolchain.cmake

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  if grep -qE "bullseye|buster|stretch" /etc/os-release 2>/dev/null; then \
    sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive; \
  fi && \
  dpkg --add-architecture armhf && \
  apt-get update && \
  apt-get --no-install-recommends install -y \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gcc-${GNU_HOST} \
    g++-${GNU_HOST} \
    git \
    gnupg \
    libc6-dev-armhf-cross \
    libcrypt-dev:armhf \
    libssl-dev \
    pkg-config \
    wget && \
  if [ -f /usr/lib/${GNU_HOST}/libcrypt.so ] && [ ! -f ${CROSS_INSTALL_PREFIX}/lib/libcrypt.so ]; then \
    mkdir -p ${CROSS_INSTALL_PREFIX}/lib && \
    ln -sf /usr/lib/${GNU_HOST}/libcrypt.so ${CROSS_INSTALL_PREFIX}/lib/libcrypt.so; \
  fi

COPY ./arm.toolchain.cmake /usr/local/share/cmake/arm.toolchain.cmake

# Raspberry Pi userland + WiringPi dependencies
FROM cross-base AS cross-pi

ARG RPI_SHA=f73fca0
ARG WIRINGPI_SHA=6d9ce35

# MMAL/VCOS (https://github.com/raspberrypi/userland)
RUN RPI_DIR=/raspberrypi && \
  RPI_BUILD_DIR=$RPI_DIR/build/arm-linux/release && \
  git clone --single-branch --branch master https://github.com/raspberrypi/userland.git $RPI_DIR && \
  cd $RPI_DIR && \
  git checkout $RPI_SHA && \
  mkdir -p $RPI_BUILD_DIR && \
  cd $RPI_BUILD_DIR && \
  cmake -DCMAKE_TOOLCHAIN_FILE=../../../makefiles/cmake/toolchains/arm-linux-gnueabihf.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    ../../.. && \
  make -j `nproc` && \
  make install DESTDIR=$CROSS_INSTALL_PREFIX/ && \
  cd / && \
  rm -rf $RPI_DIR && \
  # WiringPi
  # https://github.com/WiringPi/WiringPi
  WPI_DIR=/wpi && \
  WPI_WIRING_PI_DIR=$WPI_DIR/wiringPi && \
  git clone --single-branch --branch master https://github.com/WiringPi/WiringPi.git $WPI_DIR && \
  cd $WPI_DIR && \
  git checkout $WIRINGPI_SHA && \
  cd $WPI_WIRING_PI_DIR && \
  CC=$C_COMPILER_ARM_LINUX EXTRA_CFLAGS="-fcommon" make -j `nproc` LIBS="-L/usr/lib/$GNU_HOST -L$CROSS_INSTALL_PREFIX/lib -lm -lpthread -lrt -lcrypt" && \
  make install DESTDIR=$CROSS_INSTALL_PREFIX PREFIX="" && \
  cd / && \
  rm -rf $WPI_DIR

# Standalone builder for hello
FROM cross-base AS builder-hello

WORKDIR /code
COPY ./hello.cpp ./
RUN mkdir -p /tmp/bin && \
  $CXX_COMPILER_ARM_LINUX -std=c++17 -Wall -Werror -Ofast hello.cpp -o /tmp/bin/hello

# Builder for hello-pi (and full project)
FROM cross-pi AS builder

WORKDIR /code
COPY ./hello.cpp ./hello-pi.c ./CMakeLists.txt ./

ENV BIN_DIR=/tmp/bin
ENV BUILD_DIR=/code/build

RUN mkdir -p $BIN_DIR $BUILD_DIR && \
  cd $BUILD_DIR && \
  cmake -DCMAKE_TOOLCHAIN_FILE=$CROSS_TOOLCHAIN \
    -DCMAKE_INSTALL_PREFIX=$CROSS_INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    .. && \
  make -j `nproc` && \
  cp ./hello ./hello-pi $BIN_DIR/

FROM scratch AS export-hello
COPY --from=builder-hello /tmp/bin/hello /hello

FROM scratch AS export-hello-pi
COPY --from=builder /tmp/bin/hello-pi /hello-pi

FROM scratch AS default
COPY --from=builder /tmp/bin/hello /hello
COPY --from=builder /tmp/bin/hello-pi /hello-pi
