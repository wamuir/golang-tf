ARG BAZEL_OPTS="--config=opt"
# "--cxxopt=-D_GLIBCXX_USE_CXX11_ABI=0"
# ARG CC_OPT_FLAGS="-mavx -mavx2 -mfma -mfpmath=both -msse4.2 -Wno-sign-compare"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="1.15.5"
ARG USE_BAZEL_VERS="0.26.1"


FROM golang:1.15-buster AS base

ARG TENSORFLOW_VERS
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}

# fetch tensorflow source
RUN mkdir -p ${GOPATH}/src/github.com/tensorflow
RUN curl -fLSs https://github.com/tensorflow/tensorflow/archive/${TFV:-master}.tar.gz \
    | tar -xz -C ${GOPATH}/src/github.com/tensorflow \
    && mv ${GOPATH}/src/github.com/tensorflow/tensorflow-${TENSORFLOW_VERS:-master} \
    ${GOPATH}/src/github.com/tensorflow/tensorflow


FROM base AS builder

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
    libtool \
    tar
RUN git clone --recurse-submodules https://github.com/protocolbuffers/protobuf.git . \
    && git checkout --detach tags/v${PROTOBUF_VERS} \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && make install DESTDIR=/protobuf/build \
    && tar -czf /protobuf.tar.gz -C /protobuf/build/usr/local .

# build bazel
WORKDIR /bazel
ARG USE_BAZEL_VERS
RUN apt-get -y install --no-install-recommends \
    build-essential \
    openjdk-11-jdk \
    unzip \
    zip
RUN curl -fSsL -o bazel-dist.zip \
    https://github.com/bazelbuild/bazel/releases/download/${USE_BAZEL_VERS}/bazel-${USE_BAZEL_VERS}-dist.zip \
    && unzip bazel-dist.zip \
    && bash ./compile.sh \
    && cp output/bazel /usr/local/bin/

# build c lib for tensorflow
WORKDIR ${GOPATH}/src/github.com/tensorflow/tensorflow
ARG BAZEL_OPTS
ARG CC_OPT_FLAGS
RUN apt-get -y install --no-install-recommends \
    build-essential \
    swig
RUN . /venv/bin/activate \
    && ./configure \
    && . /venv/bin/activate \
    && bazel build ${BAZEL_OPTS} --local_cpu_resources=$(nproc) \
    //tensorflow/tools/lib_package:libtensorflow.tar.gz \
    && mv bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz \
    /libtensorflow.tar.gz


FROM base AS golang-tf

# install protoc binary and libs
COPY --from=builder /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz \
    && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=builder /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz \
    && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# patch genop.go
ARG PATCH_VERS="2.7.6"
WORKDIR /opt
RUN curl -fSLs http://ftp.gnu.org/gnu/patch/patch-${PATCH_VERS}.tar.gz | tar xz \
    && cd patch-${PATCH_VERS} \
    && ./configure \
    && make \
    && echo "@@ -267 +267 @@\n-{{- if ((len .OutArgs) eq 1) }}\n+{{- if eq (len .OutArgs) 1 }}" \
    | src/patch ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go/genop/internal/genop.go \
    && rm -rf patch-${PATCH_VERS}

# generate
RUN go generate github.com/tensorflow/tensorflow/tensorflow/go/op

# make tensorflow work with go mod
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
   && go mod init github.com/tensorflow/tensorflow \
   && cd ${GOPATH}/src/github.com/tensorflow/tensorflow/tensorflow/go \
   && ln -s vendor/github.com/tensorflow/tensorflow/tensorflow/go/core core \
   && ln -s vendor/github.com/tensorflow/tensorflow/tensorflow/go/stream_executor stream_executor

# test tensorflow module
RUN go test github.com/tensorflow/tensorflow/tensorflow/go github.com/tensorflow/tensorflow/tensorflow/go/op

WORKDIR ${GOPATH}
