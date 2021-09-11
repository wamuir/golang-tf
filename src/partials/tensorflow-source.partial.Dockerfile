

# GET TENSORFLOW SOURCE
FROM debian:buster-slim AS tensorflow-source

WORKDIR /tensorflow
ARG TF_GIT_TAG
RUN apt-get update && apt-get -y install --no-install-recommends \
    ca-certificates \
    git
RUN git clone --branch=${TF_GIT_TAG:-master} --depth=1 https://github.com/tensorflow/tensorflow.git .
