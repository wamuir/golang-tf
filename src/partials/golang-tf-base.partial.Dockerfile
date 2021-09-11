

# SET UP BASE GOLANG IMAGE
FROM golang:${GOLANG_VERS}-buster AS golang-tf-base
ARG TENSORFLOW_VERS
ARG TENSORFLOW_VERS_SUFFIX
ARG TF_GO_VERS
ENV TENSORFLOW_VERS=${TENSORFLOW_VERS}
ENV TENSORFLOW_VERS_SUFFIX=${TENSORFLOW_VERS_SUFFIX}
ENV TF_GO_VERS=${TF_GO_VERS}

# install c lib for tensorflow
RUN --mount=from=tensorflow-build,dst=/mnt \
    tar xz -C /usr/local -f /mnt/libtensorflow.tar.gz \
    && ldconfig

# add bashrc
COPY src/bashrc /etc/bash.bashrc
