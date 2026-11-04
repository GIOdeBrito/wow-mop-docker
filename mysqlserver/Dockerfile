
FROM debian:bookworm-slim as builder

RUN apt update && apt install -y unzip curl && rm -rf /var/lib/apt/lists/*

WORKDIR /db-files
RUN curl -LO https://github.com/1LineAtaTime/LoA-Pandaria-Playerbots/releases/download/v1.0.4/LoA-Pandaria-Playerbots-v1.0.4-win64-database.zip && \
	unzip LoA-Pandaria-Playerbots-v1.0.4-win64-database.zip && \
	rm LoA-Pandaria-Playerbots-v1.0.4-win64-database.zip

FROM mysql:8.0

RUN mkdir /wowsql

COPY --from=builder /db-files/*.sql /wowsql


