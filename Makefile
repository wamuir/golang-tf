PYTHON = python3

.PHONY = build construct

.DEFAULT_GOAL = construct

build: construct
	${PYTHON} assembler/assembler.py \
		--spec_file=assembler/spec.yml \
		--partial_dir=assembler/partials \
		--dockerfile_dir=build \
		--build_images \
		--hub_repository=wamuir/golang-tf \
		--repository=wamuir/golang-tf \
		--release=versioned \
		--stop_on_failure

construct:
	${PYTHON} assembler/assembler.py \
		--construct_dockerfiles \
		--release=dockerfiles \
		--spec_file=assembler/spec.yml \
		--partial_dir=assembler/partials \
		--dockerfile_dir=build
	(cd build && tar c tensorflow-*) | ( tar xf -)

