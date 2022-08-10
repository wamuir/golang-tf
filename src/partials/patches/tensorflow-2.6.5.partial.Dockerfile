# replace deprecated github.com/golang/protobuf with google.golang.org/protobuf
COPY src/patches/0001-replace-superseded-Go-protocol-buffers-module.patch .
RUN git apply 0001-replace-superseded-Go-protocol-buffers-module.patch

# disable flaky test
COPY src/patches/0001-disable-TestGenerateOp.patch .
RUN git apply 0001-disable-TestGenerateOp.patch

# apply patch to write generated source code to tensorflow source / don't vendor (#48872)
COPY src/patches/0001-simplify-generation-of-go-protos.patch .
RUN git apply 0001-simplify-generation-of-go-protos.patch

# use `go install` to install go executables 
COPY src/patches/0001-Go-Update-go-get-and-go-install-cmds-for-Go-1.17-com.patch .
RUN git apply 0001-Go-Update-go-get-and-go-install-cmds-for-Go-1.17-com.patch
