# golang-tf


## About

This repository contains Dockerfiles for using Tensorflow in Go.  You can build on your own or pull an image from Docker Hub:

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

See Tensorflow [https://github.com/tensorflow/tensorflow/issues/39307](39307), [https://github.com/tensorflow/tensorflow/issues/39744](39744), [https://github.com/tensorflow/tensorflow/issues/41808](41808), [https://github.com/tensorflow/tensorflow/issues/43847](43847), and [https://github.com/tensorflow/tensorflow/pull/44655](44655), among others.
