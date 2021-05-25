# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY patches/0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch

# apply patch to fix import name for proto package
COPY patches/0001-fix-proto-package-name.patch .
RUN git apply 0001-fix-proto-package-name.patch
