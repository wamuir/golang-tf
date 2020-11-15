ARG MACHINE="x86_64"
ARG BAZEL_OPTS="--config=opt"
ARG BAZEL_VERS="3.7.0"
ARG PROTOBUF_VERS="3.14.0"


FROM openjdk:15-buster

ARG MACHINE
ARG BAZ_OPTS
ARG BAZEL_VERS

RUN apt-get update && apt-get -y install \
    build-essential \
    libpython3-dev \
    python3 \
    python3-venv

RUN curl -fLSs https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERS}/bazel-${BAZEL_VERS}-linux-${MACHINE} \
    > /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel

WORKDIR /build/tensorflow

RUN git clone https://github.com/tensorflow/tensorflow.git .

RUN python3 -m venv /build/venv && . /build/venv/bin/activate && pip3 install numpy

RUN . /build/venv/bin/activate && ./configure 
RUN . /build/venv/bin/activate && bazel build ${BAZEL_OPTS} \
    //tensorflow/tools/lib_package:libtensorflow.tar.gz


FROM golang:1.15-buster

ARG MACHINE
ARG PROTOBUF_VERS

RUN apt-get update && apt-get install -y unzip

RUN curl -fLSs -o /tmp/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERS}/protoc-${PROTOBUF_VERS}-linux-${MACHINE}.zip \
    && unzip -q -o /tmp/protoc.zip -d /usr/local bin/protoc \
    && unzip -q -o /tmp/protoc.zip -d /usr/local 'include/*' \
    && rm /tmp/protoc.zip

COPY --from=0 /build/tensorflow/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz /tmp/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /tmp/libtensorflow.tar.gz && rm /tmp/libtensorflow.tar.gz

RUN ldconfig

RUN go get -d github.com/tensorflow/tensorflow || true

RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op

RUN go test github.com/tensorflow/tensorflow/tensorflow/go

WORKDIR ${GOPATH}
