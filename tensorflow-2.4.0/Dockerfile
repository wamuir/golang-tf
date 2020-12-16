ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.4.0"

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
RUN go test github.com/tensorflow/tensorflow/tensorflow/go

# hello from tensorflow
COPY tf.go .
RUN go run tf.go
