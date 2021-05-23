

# SET UP BASE GOLANG IMAGE
FROM golang:1.16-buster AS golang-tf-base

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=tensorflow-build /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# copy tensorflow source
COPY --from=tensorflow-source /tensorflow ${GOPATH}/src/github.com/tensorflow/tensorflow
