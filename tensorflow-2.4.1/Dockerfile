ARG BAZEL_OPTS="--config=opt --cxxopt=-D_GLIBCXX_USE_CXX11_ABI=0"
ARG USE_BAZEL_VERS="3.1.0"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.4.1"


FROM golang:1.16-buster AS base

ARG TENSORFLOW_VERS
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}

# fetch tensorflow source
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow
RUN git clone https://github.com/tensorflow/tensorflow.git . \
    && git checkout ${TFV:-master}

# build libtensorflow
FROM base as builder

RUN apt-get update

# build python venv and install numpy
RUN apt-get -y install --no-install-recommends \
    libpython3-dev \
    python3 \
    python3-venv
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && python3 -m pip install numpy

# build protoc
WORKDIR /protobuf
ARG PROTOBUF_VERS
RUN apt-get -y install --no-install-recommends \
    automake \
    autotools-dev \
    libtool
RUN git clone --recurse-submodules https://github.com/protocolbuffers/protobuf.git . \
    && ./autogen.sh \
    && ./configure \
    && cd src \
    && make -j8 protoc \
    && make install \
    && make install DESTDIR=/protobuf/build \
    && tar -czf /protobuf.tar.gz -C /protobuf/build/usr/local .

# build bazel
WORKDIR /bazel
ARG USE_BAZEL_VERS
RUN apt-get -y install --no-install-recommends \
    build-essential \
    patch \
    python3 \
    software-properties-common \
    unzip \
    wget \
    zip
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
    && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
    && apt-get update && apt-get install -y adoptopenjdk-8-hotspot
RUN curl -fSsL https://github.com/bazelbuild/bazel/releases/download/${USE_BAZEL_VERS}/bazel-${USE_BAZEL_VERS}-dist.zip \
    -o bazel-dist.zip \
    && python3 -m zipfile -e bazel-dist.zip . \
    && echo '@@ -89 +89,2 @@\n-  return "/proc/self/exe";\n+  static char path[PATH_MAX];\n+  return realpath("/proc/self/exe", path);' \
       | patch src/main/cpp/blaze_util_linux.cc \
    && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh \
    && cp output/bazel /usr/local/bin/ 

# uncomment to use bazelisk instead of building bazel (amd64 only)
# ARG USE_BAZEL_VERS
# RUN go get github.com/bazelbuild/bazelisk \
#    && ln -s ${GOPATH}/bin/bazelisk /usr/bin/bazel

# build c lib for tensorflow
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow
ARG BAZEL_OPTS
ARG CC_OPT_FLAGS
RUN apt-get -y install --no-install-recommends \
    build-essential \
    swig
RUN . /venv/bin/activate \
    && ./configure \
    && . /venv/bin/activate && bazel build ${BAZEL_OPTS} //tensorflow/tools/lib_package:libtensorflow.tar.gz \
    && mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz /libtensorflow.tar.gz


FROM base as golang-tf

# install protoc binary and libs
COPY --from=builder /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=builder /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# generate protocol buffers 
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op || true \
    && cd ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go \
    && mv vendor/github.com/tensorflow/tensorflow/tensorflow/go/* . \
    && go mod tidy \
    && go test github.com/tensorflow/tensorflow/tensorflow/go

# demo golang-tf
FROM golang-tf as demo

# hello from tensorflow (with go get)
WORKDIR /opt/build
COPY tf.go .
RUN go mod init tf-says-hello
RUN go mod edit -require github.com/tensorflow/tensorflow@v${TENSORFLOW_VERS:-$(date +"%Y.%-m.%-d")}+incompatible
RUN go mod edit -replace github.com/tensorflow/tensorflow=${GOPATH}/src/github.com/tensorflow/tensorflow
RUN go mod tidy
RUN go get && go run tf.go

# final stage
FROM golang-tf

WORKDIR ${GOPATH}
