ARG MACHINE="x86_64"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.3.1"

FROM golang:1.15-buster

ARG MACHINE
ARG PROTOBUF_VERS
ARG TENSORFLOW_VERS

RUN apt-get update && apt-get install -y unzip

RUN curl -fLSs -o /tmp/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERS}/protoc-${PROTOBUF_VERS}-linux-${MACHINE}.zip \
    && unzip -q -o /tmp/protoc.zip -d /usr/local bin/protoc \ 
    && unzip -q -o /tmp/protoc.zip -d /usr/local 'include/*' \
    && rm /tmp/protoc.zip

RUN curl -fLSs https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-${MACHINE}-${TENSORFLOW_VERS}.tar.gz \
    | tar xz -C /usr/local

RUN ldconfig

RUN mkdir -p ${GOPATH}/src/github.com/tensorflow/tensorflow
RUN curl -fLSs https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERS}.tar.gz \
    | tar xz --strip-components=1 --directory=${GOPATH}/src/github.com/tensorflow/tensorflow

RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go/vendor/github.com/tensorflow/tensorflow/tensorflow/go/core/protobuf
RUN ln -s ../core_protos_go_proto for_core_protos_go_proto

RUN go test github.com/tensorflow/tensorflow/tensorflow/go

WORKDIR ${GOPATH}
