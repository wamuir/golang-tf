# MIT License
#
# Copyright (c) 2020 William Muir
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ============================================================================
#
# THIS IS A GENERATED DOCKERFILE.
#
# This file was assembled from multiple pieces, whose use is documented
# throughout. Refer to github.com/wamuir/golang-tf for further information.

ARG GOLANG_VERS="1.19"
ARG USE_BAZEL_VERS="4.2.1"
ARG PROTOBUF_VERS="3.19.4"
ARG TENSORFLOW_VERS="2.8.2"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}

ARG TARGETARCH=${TARGETARCH:-amd64}
ARG BAZEL_OPTS_AMD64="--config=release_gpu_linux"
ARG CC_OPT_FLAGS_AMD64=""

ARG CUDA=11.2
ARG CUDA_VERSION 11.2.2
ARG CUDNN=8.1.1.33-1
ARG CUDNN_MAJOR_VERSION=8
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.2.3-1
ARG LIBNVINFER_MAJOR_VERSION=7
ARG TF_CUDA_COMPUTE_CAPABILITIES=3.5,7.5,8.6
ARG TF_CUDA_VERSION=11
ARG TF_TENSORRT_VERSION=7

# note: this libnvinfer uses cuda11.1 versions 
ARG LIBNVINFER_CUDA=11.1



# BUILD PROTOBUF
FROM debian:bullseye-slim AS protobuf-build

WORKDIR /protobuf
ARG PROTOBUF_VERS
RUN apt-get update && apt-get -y install --no-install-recommends \
    automake \
    autotools-dev \
    build-essential \
    ca-certificates \
    git \
    libtool
RUN git clone --branch=v${PROTOBUF_VERS} --depth=1 --recurse-submodules https://github.com/protocolbuffers/protobuf.git . \
    && ./autogen.sh \
    && ./configure \
    && cd src \
    && make -j$(nproc) protoc \
    && make install \
    && make install DESTDIR=/protobuf/build \
    && tar -czf /protobuf.tar.gz -C /protobuf/build/usr/local .



# BUILD BAZEL
FROM debian:bullseye-slim AS bazel-build

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



# GET TENSORFLOW SOURCE
FROM debian:bullseye-slim AS tensorflow-source

WORKDIR /tensorflow
ARG TF_GIT_TAG
RUN apt-get update && apt-get -y install --no-install-recommends \
    ca-certificates \
    git
RUN git clone --branch=${TF_GIT_TAG:-master} --depth=1 https://github.com/tensorflow/tensorflow.git .

# apply patch to declare Go import path in coordination service proto
COPY src/patches/0001-Declare-Go-import-path-in-coordination-service-proto.patch .
RUN git apply 0001-Declare-Go-import-path-in-coordination-service-proto.patch



# SET UP BASE TENSORFLOW BUILD IMAGE FOR AMD64
FROM debian:bullseye-slim AS tensorflow-build-base-amd64

ARG BAZEL_OPTS_AMD64
ARG CC_OPT_FLAGS_AMD64
ENV BAZEL_OPTS=${BAZEL_OPTS_AMD64}
ENV CC_OPT_FLAGS=${CC_OPT_FLAGS_AMD64}

# BUILD DEVTOOLSET
COPY --from=tensorflow-source /tensorflow/tensorflow/tools/ci_build/devtoolset/build_devtoolset.sh /
COPY --from=tensorflow-source /tensorflow/tensorflow/tools/ci_build/devtoolset/fixlinks.sh /
COPY --from=tensorflow-source /tensorflow/tensorflow/tools/ci_build/devtoolset/platlib.patch /
COPY --from=tensorflow-source /tensorflow/tensorflow/tools/ci_build/devtoolset/rpm-patch.sh /

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



# SET UP BASE TENSORFLOW BUILD IMAGE FOR ARM64
FROM debian:bullseye-slim AS tensorflow-build-base-arm64

ARG BAZEL_OPTS_ARM64
ARG CC_OPT_FLAGS_AMD64
ENV BAZEL_OPTS=${BAZEL_OPTS_ARM64}
ENV CC_OPT_FLAGS=${CC_OPT_FLAGS_ARM64}



# SET UP BASE TENSORFLOW BUILD IMAGE
FROM tensorflow-build-base-$TARGETARCH AS tensorflow-build-base

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install bazel binary
COPY --from=bazel-build /usr/local/bin/bazel /usr/local/bin/bazel

# link shared libraries
RUN ldconfig

# copy tensorflow source
COPY --from=tensorflow-source /tensorflow /tensorflow

ARG CUDNN_MAJOR_VERSION
ARG TF_CUDA_VERSION
ARG TF_CUDNN_VERSION
ARG TF_TENSORRT_VERSION
ARG TF_CUDA_COMPUTE_CAPABILITIES

ENV TF_NEED_CUDA=TRUE
ENV TF_CUDA_VERSION=${TF_CUDA_VERSION}
ENV TF_CUDNN_VERSION=${CUDNN_MAJOR_VERSION}
ENV TF_NEED_TENSORRT=TRUE
ENV TF_TENSORRT_VERSION=${TF_TENSORRT_VERSION}
ENV TF_CUDA_COMPUTE_CAPABILITIES=${TF_CUDA_COMPUTE_CAPABILITIES}

# source cuda package repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list


# install cuda build dependencies
# note: bash needed for string substitution
SHELL ["/bin/bash", "-c"]
ARG CUDA
ARG CUDNN
ARG CUDNN_MAJOR_VERSION
ARG LIBNVINFER
ARG LIBNVINFER_CUDA
ARG LIBNVINFER_MAJOR_VERSION
RUN apt-get update && apt-get -y install --no-install-recommends \
    cuda-command-line-tools-${CUDA/./-} \
    cuda-compat-${CUDA/./-} \
    cuda-cudart-${CUDA/./-} \
    cuda-libraries-dev-${CUDA/./-} \
    cuda-nvcc-${CUDA/./-} \
    cuda-nvprune-${CUDA/./-} \
    libcudnn${CUDNN_MAJOR_VERSION}=${CUDNN}+cuda${CUDA} \
    libcudnn${CUDNN_MAJOR_VERSION}-dev=${CUDNN}+cuda${CUDA} \
    libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}} \
    libnvinfer-dev=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}} \
    libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}} \
    libnvinfer-plugin-dev=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}}

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64
RUN ln -s cuda-${CUDA} /usr/local/cuda \
    && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig



# BUILD AND TEST LIBTENSORFLOW
FROM tensorflow-build-base AS tensorflow-build

WORKDIR /tensorflow
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



# SET UP BASE GOLANG IMAGE
FROM golang:${GOLANG_VERS}-bullseye AS golang-tf-base
ARG TENSORFLOW_VERS
ARG TENSORFLOW_VERS_SUFFIX
ARG TF_GO_VERS
ENV TENSORFLOW_VERS=${TENSORFLOW_VERS}
ENV TENSORFLOW_VERS_SUFFIX=${TENSORFLOW_VERS_SUFFIX}
ENV TF_GO_VERS=${TF_GO_VERS}

# install c lib for tensorflow
RUN --mount=from=tensorflow-build,dst=/mnt \
    tar xz -C /usr/local -f /mnt/libtensorflow.tar.gz \
    && ldconfig

# add bashrc
COPY src/bashrc /etc/bash.bashrc

# source cuda package repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# install tf dependencies
# note: bash needed for string substitution
SHELL ["/bin/bash", "-c"]
ARG CUDA
ARG CUDNN
ARG CUDNN_MAJOR_VERSION
ARG LIBNVINFER
ARG LIBNVINFER_CUDA
ARG LIBNVINFER_MAJOR_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-${CUDA/./-} \
    cuda-command-line-tools-${CUDA/./-} \
    cuda-compat-${CUDA/./-} \
    cuda-nvrtc-${CUDA/./-} \
    libcublas-${CUDA/./-} \
    libcudnn8=${CUDNN}+cuda${CUDA} \
    libcufft-${CUDA/./-} \
    libcurand-${CUDA/./-} \
    libcusolver-${CUDA/./-} \
    libcusparse-${CUDA/./-} \
    libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}} \
    libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${LIBNVINFER_CUDA:-${CUDA}}

ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
RUN ln -s cuda-${CUDA} /usr/local/cuda \
    && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig



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
RUN cp ../tensorflow/LICENSE ../tensorflow/go.mod ../tensorflow/go.sum . \
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



# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf
LABEL org.opencontainers.image.authors="William Muir <wamuir@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/wamuir/golang-tf"

# copy proxy and source
COPY --from=golang-tf-build ${GOPATH}/proxy ${GOPATH}/proxy
COPY --from=golang-tf-build ${GOPATH}/src ${GOPATH}/src

# use fileproxy
RUN go env -w \
    GOPROXY="file://${GOPATH}/proxy,$(go env GOPROXY)" \
    GONOSUMDB="github.com/tensorflow/tensorflow"

WORKDIR ${GOPATH}
