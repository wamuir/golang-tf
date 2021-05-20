FROM wamuir/golang-tf:2.5.0

WORKDIR /app

COPY tf.go .

RUN go mod init golang-tf-app \
    && go mod edit -require github.com/tensorflow/tensorflow@v2.5.0+incompatible \
    && go mod edit -replace github.com/tensorflow/tensorflow=/go/src/github.com/tensorflow/tensorflow \
    && go mod tidy

RUN go build

ENTRYPOINT ["/app/golang-tf-app"]
