# AGENTS.md

Welcome! This guide is intended for AI agents and automated tools working on the **`raspi-cross`** repository.

---

## 1. Repository Overview

This repository demonstrates how to cross-compile C and C++ applications for Raspberry Pi (specifically 32-bit ARM `armhf` / `arm-linux-gnueabihf`) without requiring physical Raspberry Pi hardware, using Docker, Docker Buildx, CMake toolchains, and QEMU user emulation.

The repository compiles two demonstrative executables:

- **`hello`** ([hello.cpp](file:///Users/roland.groza/Work/raspi-cross/hello.cpp)): A modern C++ application that reads `/sys/firmware/devicetree/base/model` to report the Raspberry Pi hardware model.
- **`hello-pi`** ([hello-pi.c](file:///Users/roland.groza/Work/raspi-cross/hello-pi.c)): A C application that interfaces directly with Raspberry Pi peripherals using Broadcom VideoCore IV / userland APIs (`vc_vchi_gencmd` to query SoC temperature) and `WiringPi` (`piBoardId` to report board model and revision).

### Key Technologies

- **Docker & Docker Buildx**: Multi-stage container builds exporting local binaries via `scratch`.
- **CMake**: Build automation and cross-compilation toolchain management ([arm.toolchain.cmake](file:///Users/roland.groza/Work/raspi-cross/arm.toolchain.cmake)).
- **Raspberry Pi Userland**: Broadcom VideoCore IV libraries (`vcos`, `vchiq_arm`, `vchostif`, `mmal`).
- **WiringPi**: GPIO and board identification library for Raspberry Pi.
- **QEMU User Emulation**: Emulating ARM target binaries on x86_64 host machines for verification and CI testing.

---

## 2. Repository Layout

```
.
├── .clang-format              # Code formatting guidelines (Google style, C/C++)
├── .editorconfig              # Code formatting guidelines (2-space indent, UTF-8)
├── .github/
│   └── workflows/
│       └── test.yml           # CI test and lint workflow using QEMU emulation
├── .gitignore                 # Ignored files (binaries, caches, editor files)
├── AGENTS.md                  # Guidance for AI coding agents (this file)
├── arm.toolchain.cmake        # CMake toolchain file for cross-compilation
├── bin/                       # Output directory for compiled binaries
│   └── .gitkeep
├── CMakeLists.txt             # CMake build configuration for hello and hello-pi
├── docker-bake.hcl            # Docker Buildx Bake configuration
├── Dockerfile                 # Unified multi-stage Docker build definition
├── dprint.json                # dprint formatting configuration (Markdown, JSON)
├── hello.cpp                  # C++ Raspberry Pi model reader demo
├── hello-pi.c                 # C demo querying board info and SoC temperature
├── LICENSE                    # MIT License
└── README.md                  # Human-facing project documentation
```

---

## 3. Architecture & Build Pipeline

The build uses a unified multi-stage [Dockerfile](file:///Users/roland.groza/Work/raspi-cross/Dockerfile):

1. **`cross-base`**:
   - Base image: `debian:bookworm-slim` (configurable via `DEBIAN_VERSION` build argument).
   - Installs native build tools, cross-compiler toolchain (`gcc-arm-linux-gnueabihf`, `g++-arm-linux-gnueabihf`, `libc6-dev-armhf-cross`), CMake, and development packages.
   - Configures the CMake cross-compilation toolchain via [arm.toolchain.cmake](file:///Users/roland.groza/Work/raspi-cross/arm.toolchain.cmake).
2. **`cross-pi`**:
   - Clones and cross-compiles Raspberry Pi `userland` (commit `f73fca0`) and `WiringPi` (commit `6d9ce35`).
   - Installs headers and shared libraries directly into the cross-staging sysroot (`/usr/arm-linux-gnueabihf`).
3. **`builder`**:
   - Configures and builds both `hello` and `hello-pi` using CMake with the cross-toolchain.
4. **`scratch` Exports**:
   - Copies the compiled executables (`hello`, `hello-pi`) to the host filesystem under `./bin`.

---

## 4. Common Commands & Workflows

### Building with Docker Buildx Bake (Recommended)

```bash
# Build both hello and hello-pi into ./bin
docker buildx bake

# Build only hello
docker buildx bake hello

# Build only hello-pi
docker buildx bake hello-pi

# Build the base cross-compiler image
docker buildx bake cross-base

# Build the base image with Raspberry Pi libraries
docker buildx bake cross-pi

# Custom output destination or cache directory
DEST=./dist CACHE=/tmp/bake-cache docker buildx bake
```

### Building with Docker Buildx directly

```bash
# Standard build exporting to ./bin
docker buildx build -f Dockerfile -o type=local,dest=./bin .

# Bust Docker layer cache
docker buildx build --no-cache -f Dockerfile -o type=local,dest=./bin .
```

### Verifying Binaries with QEMU (Linux/CI)

When cross-compiling for 32-bit ARM (`arm-linux-gnueabihf`):

```bash
# Verify ELF binary headers
file ./bin/hello
file ./bin/hello-pi

# Test hello execution with QEMU (prints empty string if device-tree model is absent on host)
qemu-arm -L /usr/arm-linux-gnueabihf/ ./bin/hello

# Test hello-pi dynamic linking and initialization with QEMU
# (Outputs board info; reports VCHI init failure when /dev/vchiq is not present on host)
qemu-arm -L /usr/arm-linux-gnueabihf/ ./bin/hello-pi
```

---

## 5. Coding Standards & Conventions

- **ClangFormat**: Google C/C++ style, 2-space indentation (see [.clang-format](file:///Users/roland.groza/Work/raspi-cross/.clang-format)).
- **EditorConfig**: 2-space indentation, trimmed trailing whitespace, newline at EOF (see [.editorconfig](file:///Users/roland.groza/Work/raspi-cross/.editorconfig)).
- **dprint**: Formatter for Markdown and JSON (see [dprint.json](file:///Users/roland.groza/Work/raspi-cross/dprint.json)).
- **typos**: Source code spell checker running in CI.
- **CMake**: Target-oriented CMake. Use `target_compile_options`, `target_include_directories`, and `target_link_libraries` rather than manipulating global directory flags.
- **C/C++**: Modern C++ (C++17) for `hello.cpp`. Standard C for `hello-pi.c`.
- **Git Hygiene & Commits**:
  - Never commit build artifacts (`hello`, `hello-pi`) to `bin/`. Only `bin/.gitkeep` should be tracked.
  - Conventional Commits, subject in imperative present tense: `feat:`, `fix:`, `chore:`, `ci:`, `docs:`, `build:`, `style:`.
  - Keep the commit body minimal, or omit it. Add a body only for non-obvious _why_ or trade-offs. Never restate the diff.
  - Disclose AI with an `Assisted-by: <Provider>:<model-id>` trailer (e.g. `Assisted-by: Antigravity:gemini-3.8-flash`), following the Linux kernel AI-assistants guide format. Never `Co-Authored-By`, and never add a human `Signed-off-by`.
  - Local commits are the hand-off point. Never push or open a PR unless explicitly asked.

---

## 6. Important Caveats & Guidance for Agents

- **Raspberry Pi Userland Architecture**: Broadcom VideoCore IV userland libraries target 32-bit ARM (`arm-linux-gnueabihf`). Modern 64-bit Raspberry Pi OS uses standard Linux KMS/DRM/V4L2 drivers rather than userland.
- **Glibc Version Matching**: The glibc version in the Docker container's sysroot must be older than or equal to the host or CI runner glibc when executing under `qemu-arm -L /usr/arm-linux-gnueabihf/`.
- **Hardware Peripherals in QEMU**: Host systems do not possess Raspberry Pi SoC hardware (`/dev/vchiq` or `/sys/firmware/devicetree/base/model`). Tests running under QEMU verify binary compilation, dynamic symbol linking, and graceful fallback handling rather than actual physical peripheral responses.
