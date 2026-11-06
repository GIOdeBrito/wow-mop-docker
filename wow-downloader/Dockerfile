FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates p7zip-full && rm -rf /var/lib/apt/lists/*

COPY download.sh /wow-downloader/download.sh
COPY download-client.sh /wow-downloader/download-client.sh
RUN chmod +x /wow-downloader/download.sh /wow-downloader/download-client.sh
