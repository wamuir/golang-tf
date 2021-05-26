variable "TF_VERSION" {}

variable "GPU" {
  default = false
}

variable "LATEST" {
  default = false
}

function "semver" {
  # IDX: MAJOR=0, MINOR=1, PATCH=2, SUFFIX=3
  params = [vers, idx]
  result = regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", "${vers}")[idx]
}

group "default" {
  targets = GPU ? ["build-cpu", "build-gpu"] : ["build-cpu"]
}

target "build-cpu" {
  dockerfile = "./tensorflow-${TF_VERSION}/cpu.Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  tags = LATEST ? [
      "wamuir/golang-tf:${TF_VERSION}",
      "wamuir/golang-tf:latest",
      "wamuir/golang-tf:${semver(TF_VERSION, 0)}",
      "wamuir/golang-tf:${semver(TF_VERSION, 0)}.${semver(TF_VERSION, 1)}"
    ] : [
      "wamuir/golang-tf:${TF_VERSION}"
    ]
}

target "build-gpu" {
  dockerfile = "./tensorflow-${TF_VERSION}/gpu.Dockerfile"
  platforms = [
    "linux/amd64"
  ]
  tags = LATEST ? [
      "wamuir/golang-tf:${TF_VERSION}-gpu",
      "wamuir/golang-tf:latest-gpu",
      "wamuir/golang-tf:${semver(TF_VERSION, 0)}-gpu",
      "wamuir/golang-tf:${semver(TF_VERSION, 0)}.${semver(TF_VERSION, 1)}-gpu"
    ] : [
      "wamuir/golang-tf:${TF_VERSION}-gpu"
    ]
}
