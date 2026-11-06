FROM ubuntu:24.04

# Runtime libs for the extractor binaries.
# vmap4assembler and mmaps_generator link libboost_filesystem (mapextractor
# and vmap4extractor need only libc/zlib, already in the base image).
RUN apt-get update && apt-get install -y --no-install-recommends libboost-filesystem1.83.0 && rm -rf /var/lib/apt/lists/*
