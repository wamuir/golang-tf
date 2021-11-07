

# BUILD BAZEL
FROM debian:bullseye-slim AS bazel-build

WORKDIR /bazel
ARG USE_BAZEL_VERS
RUN mkdir -p /usr/share/man/man1 # bug for openjdk on slim variants / man directories missing
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    curl \
    libpython3-dev \
    openjdk-11-jdk-headless \
    patch \
    python3 \
    python3-venv \
    unzip \
    zip
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && curl -fSsL https://github.com/bazelbuild/bazel/releases/download/${USE_BAZEL_VERS}/bazel-${USE_BAZEL_VERS}-dist.zip -o bazel-dist.zip \
    && unzip bazel-dist.zip \
    && echo '@@ -89 +89,2 @@\n-  return "/proc/self/exe";\n+  static char path[PATH_MAX];\n+  return realpath("/proc/self/exe", path);' \
       | patch src/main/cpp/blaze_util_linux.cc \
    && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh \
    && mv /bazel/output/bazel /usr/local/bin/bazel
