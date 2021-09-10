

# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf
LABEL org.opencontainers.image.authors="William Muir <wamuir@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/wamuir/golang-tf"

# copy source
COPY --from=golang-tf-build ${GOPATH}/src ${GOPATH}/src

# use fileproxy
RUN go env -w \
    GOPROXY="file://${GOPATH}/proxy,$(go env GOPROXY)" \
    GONOSUMDB="github.com/tensorflow/tensorflow"

WORKDIR ${GOPATH}
