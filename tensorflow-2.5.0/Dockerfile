ARG BAZEL OPS="--config=release_cpu_linux"
ARG USE_BAZEL_VERS="3.7.2"
ARG PROTOBUF_VERS="3.15.8"
ARG TENSORFLOW_VERS="2.5.0"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}



# BASE GO IMAGE
FROM golang:1.16-buster AS golang-base

# fetch tensorflow source
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow
ARG TF_GIT_TAG
RUN git clone --branch=${TF_GIT_TAG:-master} --depth=1 https://github.com/tensorflow/tensorflow.git .

# apply patch to add missing go package declarations to proto definitions (#48854)
COPY 0001-add-go_package-to-proto-definition-files.patch .
RUN git apply 0001-add-go_package-to-proto-definition-files.patch

# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY 0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch



# BASE TENSORFLOW BUILD IMAGE
FROM debian:buster-slim AS tensorflow-build-base




# BUILD PROTOBUF
FROM debian:buster-slim AS protobuf-build

WORKDIR /protobuf
ARG PROTOBUF_VERS
RUN apt-get update && apt-get -y install --no-install-recommends \
    automake \
    autotools-dev \
    build-essential \
    ca-certificates \
    git \
    libtool
RUN git clone --recurse-submodules https://github.com/protocolbuffers/protobuf.git . \
    && ./autogen.sh \
    && ./configure \
    && cd src \
    && make -j$(nproc) protoc \
    && make install \
    && make install DESTDIR=/protobuf/build \
    && tar -czf /protobuf.tar.gz -C /protobuf/build/usr/local .



# BUILD BAZEL
FROM debian:buster-slim AS bazel-build

WORKDIR /bazel
ARG USE_BAZEL_VERS
RUN mkdir -p /usr/share/man/man1 # bug for openjdk on slim variants / man directories missing
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    curl \
    libpython3-dev \
    openjdk-11-jdk-headless \
    patch \
    python3 \
    python3-venv \
    unzip \
    zip
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && curl -fSsL https://github.com/bazelbuild/bazel/releases/download/${USE_BAZEL_VERS}/bazel-${USE_BAZEL_VERS}-dist.zip -o bazel-dist.zip \
    && unzip bazel-dist.zip \
    && echo '@@ -89 +89,2 @@\n-  return "/proc/self/exe";\n+  static char path[PATH_MAX];\n+  return realpath("/proc/self/exe", path);' \
       | patch src/main/cpp/blaze_util_linux.cc \
    && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh \
    && mv /bazel/output/bazel /usr/local/bin/bazel



# BUILD DEVTOOLSET
FROM debian:buster-slim AS devtoolset-build

COPY --from=golang-base /go/src/github.com/tensorflow/tensorflow/tensorflow/tools/ci_build/devtoolset/build_devtoolset.sh /
COPY --from=golang-base /go/src/github.com/tensorflow/tensorflow/tensorflow/tools/ci_build/devtoolset/fixlinks.sh /
COPY --from=golang-base /go/src/github.com/tensorflow/tensorflow/tensorflow/tools/ci_build/devtoolset/platlib.patch /
COPY --from=golang-base /go/src/github.com/tensorflow/tensorflow/tensorflow/tools/ci_build/devtoolset/rpm-patch.sh /

WORKDIR /
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cpio \
    file \
    flex \
    rpm2cpio \
    unar \
    wget
RUN /build_devtoolset.sh devtoolset-7 /dt7 \
    && /build_devtoolset.sh devtoolset-8 /dt8



# BUILD TENSORFLOW
FROM tensorflow-build-base AS tensorflow-build

# copy tensorflow source
COPY --from=golang-base /go/src/github.com/tensorflow/tensorflow /tensorflow

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install bazel binary
COPY --from=bazel-build /usr/local/bin/bazel /usr/local/bin/bazel

# copy devtoolset
COPY --from=devtoolset-build /dt7 /dt7
COPY --from=devtoolset-build /dt8 /dt8

# link shared libraries
RUN ldconfig

# build tensorflow
WORKDIR /tensorflow
ARG BAZEL_OPTS
RUN mkdir -p /usr/share/man/man1 # bug for openjdk on slim variants / man directories missing
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    git \
    libpython3-dev \
    openjdk-11-jdk-headless \
    python3 \
    python3-venv \
    swig
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && python3 -m pip install numpy \
    && ./configure \
    && bazel test ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow_test \
    && bazel build ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow.tar.gz \
    && mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz /libtensorflow.tar.gz



# GET AND INSTALL TENSORFLOW/GO PACKAGE 
FROM golang-base AS golang-tf

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=tensorflow-build /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# generate protocol buffers 
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op \
    && go mod tidy

# test tensorflow/go modules
RUN go test github.com/tensorflow/tensorflow/tensorflow/go \
    && go test github.com/tensorflow/tensorflow/tensorflow/go/op



# DEMO TENSORFLOW/GO
FROM golang-tf as demo

# hello from tensorflow (with go get)
WORKDIR /opt/build
ARG TF_GO_VERS
COPY tf.go .
RUN go mod init tf-says-hello \
    && go mod edit -require github.com/tensorflow/tensorflow@${TF_GO_VERS:-v$(date +"%Y.%-m.%-d")+incompatible} \
    && go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod tidy \
    && go get \
    && go run tf.go



# FINAL STAGE
FROM golang-tf

WORKDIR ${GOPATH}
