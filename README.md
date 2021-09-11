# golang-tf


## About

This repository contains Dockerfiles for using Tensorflow in Go.  You can build on your own or pull an image from [wamuir/golang-tf](https://hub.docker.com/r/wamuir/golang-tf/tags?page=1&ordering=name) on Docker Hub:

```sh
docker pull wamuir/golang-tf
```

## Example Usage

See the [example Dockerfile](https://github.com/wamuir/golang-tf/blob/main/example-usage/Dockerfile).


## GPU Support

Installation of the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) is necessary for GPU use.  Then, expose the GPU(s) to the docker container using the `--gpus all` flag.  Example:

```sh
docker run -it --rm --gpus all wamuir/golang-tf:gpu
```

## Background

For background on the problem, see Tensorflow issues [39307](https://github.com/tensorflow/tensorflow/issues/39307), [39744](https://github.com/tensorflow/tensorflow/issues/39744), [41808](https://github.com/tensorflow/tensorflow/issues/41808), [43847](https://github.com/tensorflow/tensorflow/issues/43847), and [44655](https://github.com/tensorflow/tensorflow/pull/44655), among others.
