

# BUILD DEVTOOLSET
FROM debian:buster-slim AS devtoolset-build

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
