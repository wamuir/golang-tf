

# SET UP BASE TENSORFLOW BUILD IMAGE FOR AMD64
FROM debian:bullseye-slim AS tensorflow-build-base-amd64

ARG BAZEL_OPTS_AMD64
ARG CC_OPT_FLAGS_AMD64
ARG DEVTOOLSET
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
RUN echo -n ${DEVTOOLSET} | xargs -I {} -d "," /build_devtoolset.sh devtoolset-{} /dt{}



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
