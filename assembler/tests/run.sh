#!/usr/bin/env bash

set -ex

git clone https://github.com/tensorflow/build.git /build

cd /build/golang_install_guide/example-program
go mod init app && go mod tidy
go run hello_tf.go
