

# SET UP BASE GOLANG IMAGE
FROM golang:1.16-buster AS golang-tf-base
ARG TF_GIT_TAG 
ARG TF_GO_VERS
ENV TF_GIT_TAG=${TF_GIT_TAG}
ENV TF_GO_VERS=${TF_GO_VERS}

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

# add bashrc
COPY bashrc /root/.bashrc
