variable "DEST" {
  default = "./bin"
}

variable "CACHE" {
  default = "./tmp/cache"
}

variable "GNU_HOST" {
  default = "arm-linux-gnueabihf"
}

variable "DEBIAN_VERSION" {
  default = "bookworm-slim"
}

group "default" {
  targets = ["default"]
}

group "all" {
  targets = ["hello", "hello-pi"]
}

target "cross-base" {
  dockerfile = "Dockerfile"
  target     = "cross-base"
  tags       = ["cross-base:latest"]
  cache-from = ["type=local,src=${CACHE}-base"]
  cache-to   = ["type=local,mode=max,dest=${CACHE}-base"]
  args = {
    DEBIAN_VERSION = "${DEBIAN_VERSION}"
    GNU_HOST       = "${GNU_HOST}"
  }
}

target "cross-pi" {
  dockerfile = "Dockerfile"
  target     = "cross-pi"
  tags       = ["cross-pi:latest"]
  cache-from = ["type=local,src=${CACHE}-pi"]
  cache-to   = ["type=local,mode=max,dest=${CACHE}-pi"]
  args = {
    DEBIAN_VERSION = "${DEBIAN_VERSION}"
    GNU_HOST       = "${GNU_HOST}"
  }
}

target "default" {
  dockerfile = "Dockerfile"
  target     = "default"
  cache-from = ["type=local,src=${CACHE}"]
  cache-to   = ["type=local,mode=max,dest=${CACHE}"]
  output     = ["${DEST}"]
  args = {
    DEBIAN_VERSION = "${DEBIAN_VERSION}"
    GNU_HOST       = "${GNU_HOST}"
  }
}

target "hello" {
  dockerfile = "Dockerfile"
  target     = "export-hello"
  cache-from = ["type=local,src=${CACHE}-hello"]
  cache-to   = ["type=local,mode=max,dest=${CACHE}-hello"]
  output     = ["${DEST}"]
  args = {
    DEBIAN_VERSION = "${DEBIAN_VERSION}"
    GNU_HOST       = "${GNU_HOST}"
  }
}

target "hello-pi" {
  dockerfile = "Dockerfile"
  target     = "export-hello-pi"
  cache-from = ["type=local,src=${CACHE}-hello-pi"]
  cache-to   = ["type=local,mode=max,dest=${CACHE}-hello-pi"]
  output     = ["${DEST}"]
  args = {
    DEBIAN_VERSION = "${DEBIAN_VERSION}"
    GNU_HOST       = "${GNU_HOST}"
  }
}
