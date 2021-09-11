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
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - \
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
