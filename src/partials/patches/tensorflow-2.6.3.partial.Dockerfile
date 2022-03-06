# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY src/patches/0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch
