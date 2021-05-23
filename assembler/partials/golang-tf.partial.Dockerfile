

# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf
LABEL org.opencontainers.image.authors="William Muir <wamuir@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/wamuir/golang-tf"

# generate protocol buffers
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op \
    && go mod tidy

# test tensorflow/go
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go test github.com/tensorflow/tensorflow/tensorflow/go \
    && go test github.com/tensorflow/tensorflow/tensorflow/go/op

# add example app
COPY example-usage /example-app
ARG TF_GO_VERS
RUN cd /example-app \
    && go mod init example-app \
    && go mod edit -require github.com/tensorflow/tensorflow@${TF_GO_VERS} \
    && go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod tidy

WORKDIR ${GOPATH}
