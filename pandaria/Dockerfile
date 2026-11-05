
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y git cmake build-essential zlib1g-dev libssl-dev \
    libboost-thread-dev libboost-program-options-dev libboost-test-dev libboost-filesystem-dev \
    libboost-iostreams-dev libboost-locale-dev libreadline-dev libmysqlclient-dev

WORKDIR /src
RUN git clone --depth 1 --branch v1.0.4 https://github.com/1LineAtaTime/LoA-Pandaria-Playerbots.git .

WORKDIR /build
RUN cmake /src -DCMAKE_BUILD_TYPE=Release
RUN make -j4 && make install

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y libmysqlclient-dev libssl-dev \
    libboost-thread-dev libboost-program-options-dev libboost-filesystem-dev \
    libboost-iostreams-dev libboost-locale-dev zlib1g && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/ /usr/local/
WORKDIR /usr/local/bin
