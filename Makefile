PYTHON = python3

.PHONY = assemble build buildx

.DEFAULT_GOAL = assemble

assemble:
	${PYTHON} assembler/assembler.py \
		--construct_dockerfiles \
		--release=dockerfiles \
		--spec_file=assembler/spec.yml \
		--partial_dir=assembler/partials \
		--dockerfile_dir=build
	(cd build && tar c tensorflow-*) | ( tar xf -)

build: assemble
	DOCKER_BUILDKIT=1 ${PYTHON} assembler/assembler.py \
		--spec_file=assembler/spec.yml \
		--partial_dir=assembler/partials \
		--dockerfile_dir=build \
		--build_images \
		--hub_repository=wamuir/golang-tf \
		--repository=wamuir/golang-tf \
		--release=versioned \
		--run_tests_path=$(realpath ./assembler/tests) \
		--stop_on_failure

buildx: assemble
	TF_VERSION=2.5.0 GPU=true docker buildx bake --pull
