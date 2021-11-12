# apply a set of patches needed for v2.7.0 release (41bfbe8 74bf9d1 a33fba8 aa700a8 b451698 f6a59d6)
COPY src/patches/0001-v2.7.0-golang.patch .
RUN git apply 0001-v2.7.0-golang.patch
