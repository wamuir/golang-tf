ARG USE_BAZEL_VERS="0.26.1"
ARG PROTOBUF_VERS="3.14.0"
ARG TENSORFLOW_VERS="1.15.5"
ARG TENSORFLOW_VERS_SUFFIX=""
ARG TF_GIT_TAG=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}${TENSORFLOW_VERS_SUFFIX}}
ARG TF_GO_VERS=${TENSORFLOW_VERS:+v${TENSORFLOW_VERS}+incompatible}
