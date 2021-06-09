PYTHON = python3

.PHONY = assemble build buildx install-all install-docker install-multiarch install-python3

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
	TF_VERSION=2.5.0 GPU=false docker buildx bake --pull

install-all: install-docker install-multiarch install-python3
	newgrp docker

install-docker:
	sudo sh -c "$(curl -fsSL https://get.docker.com)"
	sudo systemctl enable --now docker.service
	sudo systemctl enable --now containerd.service
	(sudo groupadd docker || true)
	sudo usermod -aG docker ${USER}

install-multiarch:
	sudo apt-get update && sudo apt-get -y install qemu qemu-user-static qemu-user binfmt-support
	sudo docker run --rm --privileged multiarch/qemu-user-static:register
	sudo docker buildx create --name=multiarch --use

install-python3:
	sudo apt-get update && sudo apt-get -y install python3 python3-pip
	python3 -m pip install --upgrade --user pip
	python3 -m pip install --user -r assembler/requirements.txt
