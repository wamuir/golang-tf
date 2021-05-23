# apply patch to add missing go package declarations to proto definitions (#48854)
COPY patches/0001-add-go_package-to-proto-definition-files.patch .
RUN git apply 0001-add-go_package-to-proto-definition-files.patch

# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY patches/0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch
