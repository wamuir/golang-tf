# fix template error (rewrite a conditional in a template to be syntactically valid)
COPY 0001-genop-fix-template-error.patch .
RUN git apply 0001-genop-fix-template-error.patch

# add explicit go get for google.golang.org/protobuf/runtime/protoimpl
COPY 0001-get-protoimpl.patch .
RUN git apply 0001-get-protoimpl.patch
