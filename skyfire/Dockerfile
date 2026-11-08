FROM ubuntu:24.04 AS deps
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	gcc-14 \
	g++-14 \
	cmake \
	ninja-build \
	git \
	wget \
	ca-certificates \
	ccache \
	perl \
	pkg-config \
	bzip2 \
	libbz2-dev \
	libreadline-dev \
	zlib1g-dev \
	default-libmysqlclient-dev \
	&& rm -rf /var/lib/apt/lists/*

# Boost 1.91.0 headers only (matches upstream CI).
RUN mkdir -p /tmp/deps && cd /tmp/deps \
	&& wget -q https://archives.boost.io/release/1.91.0/source/boost_1_91_0.tar.gz \
	&& tar -xzf boost_1_91_0.tar.gz \
	&& cd boost_1_91_0 \
	&& ./bootstrap.sh \
	&& ./b2 install --prefix=/opt/boost_1_91_0 --with-headers -j$(nproc) \
	&& cd / && rm -rf /tmp/deps

# OpenSSL 4.0.0 with legacy provider (system 3.x is too old).
RUN mkdir -p /tmp/deps && cd /tmp/deps \
	&& wget -q https://www.openssl.org/source/openssl-4.0.0.tar.gz \
	&& tar -xzf openssl-4.0.0.tar.gz \
	&& cd openssl-4.0.0 \
	&& ./Configure linux-x86_64 --prefix=/opt/openssl-4.0.0 --openssldir=/opt/openssl-4.0.0/ssl shared enable-legacy \
	&& make -j$(nproc) \
	&& make install_sw install_ssldirs \
	&& cd / && rm -rf /tmp/deps

RUN find /opt/openssl-4.0.0 -name legacy.so -print | grep -q legacy.so

FROM deps AS builder
ENV DEBIAN_FRONTEND=noninteractive
ENV CC=gcc-14
ENV CXX=g++-14
ENV BOOST_ROOT=/opt/boost_1_91_0
ENV OPENSSL_ROOT_DIR=/opt/openssl-4.0.0
ENV LD_LIBRARY_PATH=/opt/openssl-4.0.0/lib64:/opt/openssl-4.0.0/lib:${LD_LIBRARY_PATH:-}

ARG SKYFIRE_REF=main
ARG BUILD_TYPE=Release
# NOPCH=1 disables all precompiled headers (Wiki recommended while Linux build stabilizes).
# Set to 0 with --build-arg NOPCH=0 to use USE_COREPCH/USE_SCRIPTPCH instead.
ARG NOPCH=1

WORKDIR /src
RUN git clone --depth 1 --branch ${SKYFIRE_REF} https://github.com/ProjectSkyfire/SkyFire_548.git .

WORKDIR /build
RUN cmake -S /src -B /build -G Ninja \
	-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	-DCMAKE_INSTALL_PREFIX=/usr/local/skyfire-server \
	-DCONF_DIR=/usr/local/skyfire-server/etc \
	-DCMAKE_C_COMPILER=${CC} \
	-DCMAKE_CXX_COMPILER=${CXX} \
	-DBOOST_ROOT=${BOOST_ROOT} \
	-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR} \
	-DTOOLS=ON \
	-DPACKET_LOG_SERVER=ON \
	-DSERVERS=ON \
	-DSCRIPTS=ON \
	-DNOPCH=${NOPCH} \
	-DSKYFIRE_BUILD_TESTS=OFF

RUN cmake --build /build --parallel $(nproc)
RUN cmake --install /build
RUN ls -lh /usr/local/skyfire-server/bin/authserver /usr/local/skyfire-server/bin/worldserver \
	&& ldd /usr/local/skyfire-server/bin/authserver | grep -E 'ssl|crypto|mysql' || true

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV OPENSSL_ROOT_DIR=/opt/openssl-4.0.0
ENV LD_LIBRARY_PATH=/opt/openssl-4.0.0/lib64:/opt/openssl-4.0.0/lib:${LD_LIBRARY_PATH:-}

RUN apt-get update && (apt-get install -y --no-install-recommends \
	libreadline8t64 \
	zlib1g \
	libbz2-1.0 \
	ca-certificates \
	|| apt-get install -y --no-install-recommends \
	libreadline8 \
	zlib1g \
	libbz2-1.0 \
	ca-certificates) \
	&& (apt-get install -y --no-install-recommends libmysqlclient21 || apt-get install -y --no-install-recommends default-libmysqlclient21) \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/openssl-4.0.0 /opt/openssl-4.0.0
COPY --from=builder /usr/local/skyfire-server /usr/local/skyfire-server
RUN echo /opt/openssl-4.0.0/lib64 > /etc/ld.so.conf.d/skyfire-openssl.conf \
	&& echo /opt/openssl-4.0.0/lib >> /etc/ld.so.conf.d/skyfire-openssl.conf \
	&& ldconfig \
	&& ls -lh /usr/local/skyfire-server/bin/

WORKDIR /usr/local/skyfire-server/bin
