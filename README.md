# golang-tf


## About

This repository contains Dockerfiles for using Tensorflow in Go.  You can build on your own or pull an image from [wamuir/golang-tf](https://hub.docker.com/r/wamuir/golang-tf/tags?page=1&ordering=name) on Docker Hub:

```sh
docker pull wamuir/golang-tf:2.4.0
```

## Usage with Go Modules

Go modules (`go mod`) will work when using the image.  Use the `require` and `replace` flags as follows:

```sh
go mod edit -require github.com/tensorflow/tensorflow@v2.4.0+incompatible
go mod edit -replace github.com/tensorflow/tensorflow=/go/src/github.com/tensorflow/tensorflow
```

## Background

For background on the problem, see Tensorflow issues [39307](https://github.com/tensorflow/tensorflow/issues/39307), [39744](https://github.com/tensorflow/tensorflow/issues/39744), [41808](https://github.com/tensorflow/tensorflow/issues/41808), [43847](https://github.com/tensorflow/tensorflow/issues/43847), and [44655](https://github.com/tensorflow/tensorflow/pull/44655), among others.
