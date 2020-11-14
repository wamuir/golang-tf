FROM golang:1.15-buster

ENV MACHINE="x86_64"
ENV PROTOBUF_VERSION="3.14.0"
ENV TENSORFLOW_VERSION="2.3.1"

RUN apt-get update && apt-get install -y unzip

RUN curl -fLSs -o /tmp/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-${MACHINE}.zip \
    && unzip -q -o /tmp/protoc.zip -d /usr/local bin/protoc \ 
    && unzip -q -o /tmp/protoc.zip -d /usr/local 'include/*' \
    && rm /tmp/protoc.zip

RUN curl -fLSs https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-${MACHINE}-${TENSORFLOW_VERSION}.tar.gz \
    | tar xz -C /usr/local

RUN ldconfig

RUN mkdir -p /go/src/github.com/tensorflow/tensorflow
RUN curl -fLSs https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
    | tar xz --strip-components=1 --directory=/go/src/github.com/tensorflow/tensorflow

RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op
WORKDIR /go/src/github.com/tensorflow/tensorflow/tensorflow/go/vendor/github.com/tensorflow/tensorflow/tensorflow/go/core/protobuf
RUN ln -s ../core_protos_go_proto for_core_protos_go_proto

RUN go test github.com/tensorflow/tensorflow/tensorflow/go
