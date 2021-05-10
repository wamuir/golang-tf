ARG BAZEL OPS="--config=release_cpu_linux"
ARG USE_BAZEL_VERS="3.7.2"
ARG PROTOBUF_VERS="3.15.8"
ARG TENSORFLOW_VERS="2.5.0-rc3"



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
    && make -j8 protoc \
    && make install \
    && make install DESTDIR=/protobuf/build \
    && tar -czf /protobuf.tar.gz -C /protobuf/build/usr/local . \
    && rm -rf /protobuf



# BUILD BAZEL
FROM debian:buster-slim AS bazel-build

WORKDIR /bazel
ARG USE_BAZEL_VERS
RUN mkdir -p /usr/share/man/man1
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
    && mv /bazel/output/bazel /usr/local/bin/bazel \
    && rm -rf /bazel

# uncomment to use bazelisk instead of building bazel (amd64 only)
# ARG USE_BAZEL_VERS
# RUN go get github.com/bazelbuild/bazelisk \
#    && ln -s ${GOPATH}/bin/bazelisk /usr/bin/bazel



# BUILD TENSORFLOW
FROM debian:buster-slim AS tensorflow-build

COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz
COPY --from=bazel-build /usr/local/bin/bazel /usr/local/bin/bazel
RUN ldconfig

WORKDIR /tensorflow
ARG BAZEL_OPTS
ARG CC_OPT_FLAGS
ARG TENSORFLOW_VERS
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}
RUN mkdir -p /usr/share/man/man1
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
    && git clone --branch=${TFV:-master} --depth=1 https://github.com/tensorflow/tensorflow.git . \
    && ./configure \
    && bazel test ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow_test \
    && bazel build ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow.tar.gz \
    && mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz /libtensorflow.tar.gz \
    && rm -rf /tensorflow



# GET AND INSTALL TENSORFLOW/GO PACKAGE 
FROM golang:1.16-buster AS golang-tf

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=tensorflow-build /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# fetch tensorflow source and apply patches
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow
ARG TENSORFLOW_VERS
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}
RUN git clone --branch=${TFV:-master} --depth=1 https://github.com/tensorflow/tensorflow.git .
COPY 0001-add-go_package-to-proto-definition-files.patch .
RUN git apply 0001-add-go_package-to-proto-definition-files.patch
COPY 0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch

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
COPY tf.go .
RUN go mod init tf-says-hello
RUN go mod edit -require github.com/tensorflow/tensorflow@v${TENSORFLOW_VERS:-$(date +"%Y.%-m.%-d")}+incompatible
RUN go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow
RUN go mod tidy
RUN go get && go run tf.go



# FINAL STAGE
FROM golang-tf

WORKDIR ${GOPATH}
