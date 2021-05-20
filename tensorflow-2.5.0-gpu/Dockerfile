ARG BAZEL OPS="--config=release_gpu_linux"
ARG USE_BAZEL_VERS="3.7.2"
ARG PROTOBUF_VERS="3.15.8"
ARG TENSORFLOW_VERS="2.5.0"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}

ARG CUDA=11.2
ARG CUDA_VERSION 11.2.2
ARG CUDNN=8.1.0.77-1
ARG CUDNN_MAJOR_VERSION=8
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.2.2-1
ARG LIBNVINFER_MAJOR_VERSION=7
ARG TF_CUDA_COMPUTE_CAPABILITIES=3.5,7.5,8.6
ARG TF_CUDA_VERSION=11
ARG TF_TENSORRT_VERSION=7



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



# SET UP BASE TENSORFLOW BUILD IMAGE
FROM debian:buster-slim AS tensorflow-build-base

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install bazel binary
COPY --from=bazel-build /usr/local/bin/bazel /usr/local/bin/bazel

# link shared libraries
RUN ldconfig

# copy devtoolset
COPY --from=devtoolset-build /dt7 /dt7
COPY --from=devtoolset-build /dt8 /dt8

# fetch tensorflow source
WORKDIR /tensorflow
ARG TF_GIT_TAG
RUN apt-get update && apt-get -y install --no-install-recommends \
    ca-certificates \
    git
RUN git clone --branch=${TF_GIT_TAG:-master} --depth=1 https://github.com/tensorflow/tensorflow.git .

# apply patch to add missing go package declarations to proto definitions (#48854)
COPY 0001-add-go_package-to-proto-definition-files.patch .
RUN git apply 0001-add-go_package-to-proto-definition-files.patch

# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY 0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch


ARG TF_CUDA_VERSION
ARG TF_CUDNN_VERSION
ARG TF_TENSORRT_VERSION
ARG TF_COMPUTE_CAPABILITIES

ENV TF_NEED_CUDA=TRUE
ENV TF_CUDA_VERSION=${TF_CUDA_VERSION}
ENV TF_CUDNN_VERSION=${TF_CUDNN_VERSION}
ENV TF_NEED_TENSORRT=TRUE
ENV TF_TENSORRT_VERSION=${TF_TENSORRT_VERSION}
ENV TF_CUDA_COMPUTE_CAPABILITIES=${TF_CUDA_COMPUTE_CAPABILITIES}

# source cuda package repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# install cuda build dependencies
# note: bash needed for string substitution
SHELL ["/bin/bash", "-c"]
ARG CUDA
ARG CUDNN
ARG CUDNN_MAJOR_VERSION
RUN apt-get update && apt-get -y install --no-install-recommends \
    cuda-command-line-tools-${CUDA/./-} \
    cuda-compat-${CUDA/./-} \
    cuda-cudart-${CUDA/./-} \
    cuda-libraries-dev-${CUDA/./-} \
    cuda-nvcc-${CUDA/./-} \
    cuda-nvprune-${CUDA/./-} \
    libcudnn${CUDNN_MAJOR_VERSION}=${CUDNN}+cuda${CUDA} \
    libcudnn${CUDNN_MAJOR_VERSION}-dev=${CUDNN}+cuda${CUDA} \
    libnvinfer-dev=7.2.3-1+cuda11.1 \
    libnvinfer-plugin-dev=7.2.3-1+cuda11.1

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64
RUN ln -s cuda-11.2 /usr/local/cuda \
    && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig



# BUILD AND TEST LIBTENSORFLOW
FROM tensorflow-build-base AS tensorflow-build

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



# SET UP BASE GOLANG IMAGE
FROM golang:1.16-buster AS golang-tf-base

# install protoc binary and libs
COPY --from=protobuf-build /protobuf.tar.gz /opt/protobuf.tar.gz
RUN tar xz -C /usr/local -f /opt/protobuf.tar.gz && rm /opt/protobuf.tar.gz

# install c lib for tensorflow
COPY --from=tensorflow-build /libtensorflow.tar.gz /opt/libtensorflow.tar.gz
RUN tar xz -C /usr/local -f /opt/libtensorflow.tar.gz && rm /opt/libtensorflow.tar.gz

# link shared libs
RUN ldconfig

# copy tensorflow source
COPY --from=tensorflow-build-base /tensorflow ${GOPATH}/src/github.com/tensorflow/tensorflow

# source cuda package repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# install tf dependencies
# note: bash needed for string substitution
# note: libnvinfer uses cuda11.1 versions
SHELL ["/bin/bash", "-c"]
ARG CUDA
ARG CUDNN
ARG CUDNN_MAJOR_VERSION
ARG LIBNVINFER
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
    libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda11.1 \
    libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda11.1

ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
RUN ln -s cuda-11.2 /usr/local/cuda \
    && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig



# INSTALL AND TEST TENSORFLOW/GO PACKAGE
FROM golang-tf-base as golang-tf

# generate protocol buffers 
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go mod init \
    && go generate github.com/tensorflow/tensorflow/tensorflow/go/op \
    && go mod tidy

# test tensorflow/go
RUN cd ${GOPATH}/src/github.com/tensorflow/tensorflow \
    && go test github.com/tensorflow/tensorflow/tensorflow/go \
    && go test github.com/tensorflow/tensorflow/tensorflow/go/op

WORKDIR ${GOPATH}
