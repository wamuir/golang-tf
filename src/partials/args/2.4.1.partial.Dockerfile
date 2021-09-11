ARG GOLANG_VERS="1.16"
ARG USE_BAZEL_VERS="3.1.0"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="2.4.1"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}