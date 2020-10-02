variable "STRETCH_TAG" {
	default = "latest"
}

variable "PI_TAG" {
	default = "latest"
}

variable "DEST" {
	default = "./bin"
}

target "cross-stretch" {
	dockerfile = "Dockerfile.cross"
	tags = ["cross-stretch:${STRETCH_TAG}"]
}

target "cross-pi" {
	dockerfile = "Dockerfile.cross-pi"
	tags = ["cross-pi:${PI_TAG}"]
}

group "default" {
	targets = ["hello", "hello-pi"]
}

target "hello" {
	dockerfile = "Dockerfile.hello"
	output = ["${DEST}"]
}

target "hello-pi" {
	dockerfile = "Dockerfile.hello-pi"
	output = ["${DEST}"]
}
