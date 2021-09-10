FROM wamuir/golang-tf

# Build example program
WORKDIR /example-program
COPY hello_tf.go .
RUN go mod init app \
    && go mod tidy \
    && go build

ENTRYPOINT ["/example-program/app"]
