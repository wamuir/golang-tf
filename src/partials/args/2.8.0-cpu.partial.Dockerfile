ARG TARGETARCH=${TARGETARCH:-amd64}
ARG BAZEL_OPTS_AMD64="--config=release_cpu_linux --crosstool_top=@bazel_tools//tools/cpp:toolchain"
ARG BAZEL_OPTS_ARM64="--config=release_base --test_env=LD_LIBRARY_PATH"
ARG CC_OPT_FLAGS_AMD64=""
ARG CC_OPT_FLAGS_ARM64=""
