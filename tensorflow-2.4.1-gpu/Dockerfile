ARG BAZEL_OPTS="--config=opt --config=cuda --cxxopt=-D_GLIBCXX_USE_CXX11_ABI=0"
ARG USE_BAZEL_VERS="3.1.0"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.4.1"


FROM golang:1.16-buster AS base


### cuda part one
# https://gitlab.com/nvidia/container-images/cuda/-/blob/f08ab8553644c74e146e634d3e2e79de466bcbca/dist/11.0/ubuntu18.04-x86_64/base/Dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*


ENV CUDA_VERSION 11.0.3

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-0=11.0.221-1 \
    cuda-compat-11-0 \
    && ln -s cuda-11.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.0 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 brand=tesla,driver>=450,driver<451"



### cuda part two
# https://github.com/tensorflow/tensorflow/blob/v2.4.1/tensorflow/tools/dockerfiles/dockerfiles/gpu.Dockerfile
ARG CUDA=11.0
ARG CUDNN=8.0.5.39-1
ARG CUDNN_MAJOR_VERSION=8
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.1.3-1
ARG LIBNVINFER_MAJOR_VERSION=7

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        libcublas-${CUDA/./-} \
        cuda-nvrtc-${CUDA/./-} \
        libcufft-${CUDA/./-} \
        libcurand-${CUDA/./-} \
        libcusolver-${CUDA/./-} \
        libcusparse-${CUDA/./-} \
        curl \
        libcudnn8=${CUDNN}+cuda${CUDA} \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

# Install TensorRT if not building for PowerPC
RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }


# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ls -l /usr/local/cuda/lib64/
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig


# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8



# fetch tensorflow source
ARG TENSORFLOW_VERS
ARG TFV=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}}
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
SHELL ["/bin/sh", "-c"]
RUN curl -fSsL https://github.com/bazelbuild/bazel/releases/download/${USE_BAZEL_VERS}/bazel-${USE_BAZEL_VERS}-dist.zip \
    -o bazel-dist.zip \
    && python3 -m zipfile -e bazel-dist.zip .
RUN echo '@@ -89 +89,2 @@\n-  return "/proc/self/exe";\n+  static char path[PATH_MAX];\n+  return realpath("/proc/self/exe", path);' | patch src/main/cpp/blaze_util_linux.cc \
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
RUN apt-get -y install \
    cuda-libraries-dev-11-0 \
    libcudnn8-dev=8.0.5.39-1+cuda11.0
ARG TF_NEED_CUDA=TRUE
ARG TF_CUDA_VERSION=11
ARG TF_CUDNN_VERSION=8
RUN . /venv/bin/activate \
    && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64 \
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
