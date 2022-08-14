ARG DEVTOOLSET="7,8"
ARG GOLANG_VERS="1.19"
ARG USE_BAZEL_VERS="4.2.1"
ARG PROTOBUF_VERS="3.19.4"
ARG TENSORFLOW_VERS="2.8.2"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}