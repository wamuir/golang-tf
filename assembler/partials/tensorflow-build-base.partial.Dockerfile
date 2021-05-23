

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

# copy tensorflow source
COPY --from=tensorflow-source /tensorflow /tensorflow
