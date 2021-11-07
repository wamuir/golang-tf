

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
