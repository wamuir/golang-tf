ARG BAZEL_OPTS="--config=opt"
ARG BAZEL_VERS="3.7.2"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS

FROM openjdk:15-buster

ARG BAZEL_OPTS
ARG BAZEL_VERS
ARG TENSORFLOW_VERS

RUN apt-get update && apt-get -y install \
    build-essential \
    libpython3-dev \
    python3 \
    python3-venv \
    swig

# fetch and install bazel
RUN curl -fLSs https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERS}/bazel-${BAZEL_VERS}-linux-`uname -m` \
    > /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel

# build venv and install numpy
RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate && pip3 install numpy

# fetch tensorflow source
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}
RUN curl -fLSs -o /opt/tensorflow.tar.gz \
    https://github.com/tensorflow/tensorflow/archive/${TFV:-master}.tar.gz \
    && tar -xz -C /opt -f /opt/tensorflow.tar.gz
RUN mv /opt/tensorflow-${TENSORFLOW_VERS:-master} /opt/tensorflow

# build and install c lib for tensorflow
WORKDIR /opt/tensorflow
RUN . /opt/venv/bin/activate && ./configure
RUN . /opt/venv/bin/activate && bazel build ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow.tar.gz
RUN tar xz -C /usr/local -f bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz


FROM golang:1.15-buster

ARG PROTOBUF_VERS
ARG TENSORFLOW_VERS

# fetch and install protoc
RUN curl -fLSs -o /opt/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERS}/protoc-${PROTOBUF_VERS}-linux-`uname -m`.zip \
    && python -m zipfile -e /opt/protoc.zip /usr/local \
    && chmod +x /usr/local/bin/protoc

# install c lib for tensorflow
COPY --from=0 /opt/tensorflow/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# fetch tensorflow source
RUN mkdir -p ${GOPATH}/src/github.com/tensorflow
COPY --from=0 /opt/tensorflow.tar.gz /opt/tensorflow.tar.gz
RUN tar -xz -C ${GOPATH}/src/github.com/tensorflow -f /opt/tensorflow.tar.gz
RUN mv ${GOPATH}/src/github.com/tensorflow/tensorflow-${TENSORFLOW_VERS:-master} ${GOPATH}/src/github.com/tensorflow/tensorflow

# generate and test
RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op
RUN go test github.com/tensorflow/tensorflow/tensorflow/go

# make tensorflow work with go mod
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init github.com/tensorflow/tensorflow
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go \
    && ln -s vendor/github.com/tensorflow/tensorflow/tensorflow/go/core core \
    && ln -s vendor/github.com/tensorflow/tensorflow/tensorflow/go/stream_executor stream_executor

# hello from tensorflow
WORKDIR /opt/build
COPY tf.go .
RUN go run tf.go

# hello from tensorflow (with go get)
WORKDIR /opt/build
COPY tf.go .
RUN go mod init tf-says-hello
RUN go mod edit -require github.com/tensorflow/tensorflow@v${TENSORFLOW_VERS:-2.5.0}+incompatible
RUN go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow
RUN go get && go run tf.go

WORKDIR $GOPATH
