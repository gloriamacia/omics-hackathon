# -------- FastqWiper + gzrecover (amd64) --------
FROM --platform=linux/amd64 python:3.11-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# System deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl git build-essential zlib1g-dev pigz && \
    rm -rf /var/lib/apt/lists/*

# Build gzrecover from gzrt (no install target; copy binary)
RUN git clone https://github.com/arenn/gzrt.git /tmp/gzrt && \
    make -C /tmp/gzrt && \
    install -m 0755 /tmp/gzrt/gzrecover /usr/local/bin/gzrecover && \
    rm -rf /tmp/gzrt

# Install FastqWiper CLI (wipertools)
RUN pip install --no-cache-dir fastqwiper

WORKDIR /work
