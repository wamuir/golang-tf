ARG MACHINE="x86_64"
ARG TENSORFLOW_VERS="1.15.0"

FROM golang:1.15-buster

ARG MACHINE
ARG TENSORFLOW_VERS

RUN curl -fLSs https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-${MACHINE}-${TENSORFLOW_VERS}.tar.gz \
    | tar xz -C /usr/local

RUN ldconfig

RUN mkdir -p /go/src/github.com/tensorflow/tensorflow
RUN curl -fLSs https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERS}.tar.gz \
    | tar xz --strip-components=1 --directory=/go/src/github.com/tensorflow/tensorflow

RUN go test github.com/tensorflow/tensorflow/tensorflow/go
