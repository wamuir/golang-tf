FROM golang:1.15-buster

ENV TENSORFLOW_VERSION="2.3.1"
ENV PROTOBUF_VERSION="3.13.0"

RUN apt-get update && apt-get install -y unzip

RUN mkdir /build

RUN curl -fLSs -o /build/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip \
    && unzip -q -o /build/protoc.zip -d /usr/local bin/protoc \ 
    && unzip -q -o /build/protoc.zip -d /usr/local 'include/*'

RUN curl -fLSs -o /build/libtensorflow.tar.gz \
    https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-${TENSORFLOW_VERSION}.tar.gz \
    && tar xz -C /usr/local -f /build/libtensorflow.tar.gz

RUN ldconfig

RUN go get -d github.com/tensorflow/tensorflow/tensorflow/go/op || true
WORKDIR /go/src/github.com/tensorflow/tensorflow/tensorflow
RUN git checkout -q tags/v${TENSORFLOW_VERSION}

WORKDIR go/vendor/github.com/tensorflow/tensorflow/tensorflow/go/core/protobuf
RUN ln -s ../core_protos_go_proto for_core_protos_go_proto

RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op

WORKDIR /go/src/github.com/wamuir/golang-tf
COPY test.go .
RUN CGO_ENABLED=1 GOOS=linux go build -o /go/bin/golang-tf


FROM debian:buster-slim

WORKDIR /build

COPY --from=0 /build/libtensorflow.tar.gz .
RUN tar xz -C /usr/local -f /build/libtensorflow.tar.gz
RUN rm /build/libtensorflow.tar.gz

RUN ldconfig

COPY --from=0 /go/bin/golang-tf /usr/bin/golang-tf
RUN /usr/bin/golang-tf
