ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.3.1"

FROM golang:1.15-buster

ARG PROTOBUF_VERS
ARG TENSORFLOW_VERS

# fetch and install protoc
RUN curl -fLSs -o /opt/protoc.zip \
    https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERS}/protoc-${PROTOBUF_VERS}-linux-`uname -m`.zip \
    && python -m zipfile -e /opt/protoc.zip /usr/local \
    && chmod +x /usr/local/bin/protoc

# fetch and install tensorflow c libs
RUN curl -fLSs -o /opt/libtensorflow.tar.gz \
    https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-`uname -m`-${TENSORFLOW_VERS}.tar.gz \
    && tar xz -C /usr/local -f /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# fetch tensorflow source
RUN mkdir -p ${GOPATH}/src/github.com/tensorflow
RUN curl -fLSs -o /opt/tensorflow.tar.gz \
    https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERS}.tar.gz \
    && tar -xz -C ${GOPATH}/src/github.com/tensorflow -f /opt/tensorflow.tar.gz
RUN mv ${GOPATH}/src/github.com/tensorflow/tensorflow-${TENSORFLOW_VERS} ${GOPATH}/src/github.com/tensorflow/tensorflow

# generate and test
RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go/vendor/github.com/tensorflow/tensorflow/tensorflow/go/core/protobuf
RUN ln -s ../core_protos_go_proto for_core_protos_go_proto
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
RUN go mod edit -require github.com/tensorflow/tensorflow@v${TENSORFLOW_VERS}+incompatible
RUN go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow
RUN go get && go run tf.go

WORKDIR $GOPATH
