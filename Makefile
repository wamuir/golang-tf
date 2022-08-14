.PHONY = assemble build buildx proxy
.DEFAULT_GOAL = assemble

PYTHON = python3
TF_VERSION := 2.9.1
GPU := true
LATEST := true

assemble:
	${PYTHON} src/assembler.py \
		--construct_dockerfiles \
		--release=dockerfiles \
		--spec_file=src/spec.yml \
		--partial_dir=src/partials \
		--dockerfile_dir=dockerfiles

build: assemble
	DOCKER_BUILDKIT=1 ${PYTHON} src/assembler.py \
		--spec_file=src/spec.yml \
		--partial_dir=src/partials \
		--dockerfile_dir=dockerfiles \
		--build_images \
		--hub_repository=wamuir/golang-tf \
		--repository=wamuir/golang-tf \
		--release=versioned \
		--run_tests_path=$(realpath ./src/tests) \
		--stop_on_failure

buildx: assemble
	TF_VERSION=$(TF_VERSION) GPU=$(GPU) LATEST=$(LATEST) docker buildx bake

proxy:
	src/modproxy $(TF_VERSION)
