

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
