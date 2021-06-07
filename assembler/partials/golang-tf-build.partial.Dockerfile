

# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf-build

# copy tensorflow source, selectively
COPY --from=tensorflow-source \
     /tensorflow/tensorflow/go \
     ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS}/tensorflow/go
COPY --from=tensorflow-source \
     /tensorflow/tensorflow/cc/saved_model/testdata/half_plus_two \
     ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS}/tensorflow/cc/saved_model/testdata/half_plus_two
COPY --from=tensorflow-source \
     /tensorflow/ACKNOWLEDGEMENTS \
     /tensorflow/LICENSE \
     ${GOPATH}/src/github.com/tensorflow/tensorflow${TF_GO_VERS}/

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# generate protocol buffers
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op \
    && go mod tidy

# test tensorflow/go
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go \
    && go test ./...

# create files for proxy
WORKDIR ${GOPATH}/src/cache/github.com/tensorflow/tensorflow/@v
RUN echo "${TF_GO_VERS}" > list
    && cp ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS}/go.mod ${TF_GO_VERS}.mod
    && echo "{\"Version\": \"${TF_GO_VERS}\",\"Time\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" > ${TF_GO_VERS}.info
RUN apt-get update && apt-get -y install --no-install-recommends \
    zip
RUN cd ${GOPATH}/src && zip -r -9 \
    cache/github.com/tensorflow/tensorflow/@v/${TF_GO_VERS}.zip \
    github.com/tensorflow/tensorflow@${TF_GO_VERS}

# symbolic link for compat with legacy `go mod -replace` instructions
RUN ln -s tensorflow@${TF_GO_VERS} ${GOPATH}/src/github.com/tensorflow/tensorflow
