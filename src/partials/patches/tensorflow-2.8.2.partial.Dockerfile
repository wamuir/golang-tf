# apply patch to declare Go import path in coordination service proto
COPY src/patches/0001-Declare-Go-import-path-in-coordination-service-proto.patch .
RUN git apply 0001-Declare-Go-import-path-in-coordination-service-proto.patch
