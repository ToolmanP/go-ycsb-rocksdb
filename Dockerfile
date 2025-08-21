FROM golang:1.18.4-alpine3.16

ENV GOPATH /go

RUN apk update && apk upgrade && \ 
    apk add --no-cache git build-base wget linux-headers \
    sqlite-dev sqlite-static zlib-dev zlib-static gflags-dev \
    bash perl


RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
 && chmod +x /usr/local/bin/dumb-init

RUN mkdir -p /go/src/github.com/pingcap/go-ycsb
WORKDIR /go/src/github.com/pingcap/go-ycsb

COPY go.mod .
COPY go.sum .
RUN GO111MODULE=on go mod download

COPY . .
RUN make EXTRA_CXXFLAGS="-Wno-range-loop-construct -Wno-maybe-uninitialized" -C thirdparty/rocksdb install -j$(nproc)
RUN make STATIC=1 DESTDIR=/

FROM alpine:3.16
COPY --from=0 /go-ycsb /go-ycsb
COPY --from=0 /usr/local/bin/dumb-init /usr/local/bin/dumb-init

ADD workloads /workloads

EXPOSE 6060

ENTRYPOINT [ "/usr/local/bin/dumb-init", "/go-ycsb" ]
