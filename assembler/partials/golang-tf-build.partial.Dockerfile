

# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf-build

# copy tensorflow source
COPY --from=tensorflow-source /tensorflow ${GOPATH}/src/github.com/tensorflow/tensorflow

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz \
    && ldconfig \
    && rm /opt/protobuf.tar.gz

# generate protocol buffers
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op \
    && go mod tidy

# test tensorflow/go
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go \
    && go test ./...

# copy tensorflow source, selectively
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS}
RUN cp ../tensorflow/ACKNOWLEDGMENTS ../tensorflow/LICENSE ../tensorflow/go.mod ../tensorflow/go.sum . \
    && mkdir -p tensorflow && cd tensorflow && cp -r ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go . \
    && mkdir -p cc/saved_model/testdata && cd cc/saved_model/testdata && cp -r ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/cc/saved_model/testdata/half_plus_two .

# create files for proxy
WORKDIR ${GOPATH}/proxy/github.com/tensorflow/tensorflow/@v
RUN echo "${TF_GO_VERS}" > list \
    && cp ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS}/go.mod ${TF_GO_VERS}.mod \
    && echo "{\"Version\": \"${TF_GO_VERS}\",\"Time\":\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}" > ${TF_GO_VERS}.info
RUN apt-get update && apt-get -y install --no-install-recommends \
    zip
RUN cd ${GOPATH}/src && zip -r -9 \
    ../proxy/github.com/tensorflow/tensorflow/@v/${TF_GO_VERS}.zip \
    github.com/tensorflow/tensorflow@${TF_GO_VERS}

# rename tf/go source for compat with legacy `go mod -replace` instructions
RUN rm -rf ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && mv ${GOPATH}/src/github.com/tensorflow/tensorflow@${TF_GO_VERS} ${GOPATH}/src/github.com/tensorflow/tensorflow
