FROM debian:testing

RUN apt update && apt install -y git cmake build-essential zlib1g-dev libssl-dev \
	libboost-thread-dev libboost-program-options-dev libboost-test-dev libboost-filesystem-dev \
	libboost-iostreams-dev libboost-locale-dev libreadline-dev default-libmysqlclient-dev

RUN git clone --depth 1 --branch v1.0.4 https://github.com/1LineAtaTime/LoA-Pandaria-Playerbots.git && \
	mkdir build && cd build && \
	cmake ../LoA-Pandaria-Playerbots -DCMAKE_BUILD_TYPE=Release && \
	make -j$(nproc) && make install
