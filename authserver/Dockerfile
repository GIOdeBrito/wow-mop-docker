FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y libmysqlclient-dev libssl-dev \
    libboost-thread-dev libboost-program-options-dev libboost-filesystem-dev \
    libboost-iostreams-dev libboost-locale-dev libreadline-dev zlib1g && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/bin
