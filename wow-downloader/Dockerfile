FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY download.sh /wow-downloader/download.sh
RUN chmod +x /wow-downloader/download.sh
