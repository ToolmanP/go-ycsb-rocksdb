FROM toolmanp/ubuntu:22.04-zpoline AS builder

RUN apt update && apt upgrade -y
RUN apt install liblz4-dev libzstd-dev libsnappy-dev bzip2 libsqlite3-dev golang build-essential ca-certificates -y
RUN apt clean 
RUN mkdir -p /go/src/github.com/pingcap/go-ycsb
WORKDIR /go/src/github.com/pingcap/go-ycsb
COPY go.mod .
COPY go.sum .
RUN GO111MODULE=on go mod download
COPY . .
RUN make EXTRA_CXXFLAGS="-Wno-range-loop-construct -Wno-maybe-uninitialized" -C thirdparty/rocksdb install-shared -j$(nproc)
RUN make DESTDIR=/
RUN ldconfig


FROM toolmanp/ubuntu:22.04-zpoline
RUN apt update && apt upgrade -y
RUN apt install liblz4-dev libzstd-dev libsnappy-dev bzip2 libsqlite3-dev -y
RUN apt clean 
COPY workloads /workloads
COPY --from=builder /go-ycsb /usr/local/bin/
COPY --from=builder /usr/local/lib/librocksdb* /usr/local/lib/
RUN ldconfig
