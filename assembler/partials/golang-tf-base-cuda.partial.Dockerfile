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
