# Compile - dependency-layer trick
# Copy only Cargo manifests first, fetch dependencies to create a cached layer,
# then copy source and perform release build. This keeps dependency resolution
# and download in an earlier layer so CI remote cache is effective.
FROM rust:1.89-alpine3.22 AS builder
RUN apk add -q --no-cache build-base openssl-dev git
WORKDIR /app

COPY . .

# Create a tiny dummy main so cargo can operate and fetch dependencies.
RUN mkdir -p src && echo 'fn main() { println!("dummy"); }' > src/main.rs

# Fetch dependencies (populates cargo registry/git cache).
RUN cargo build --release -p meilisearch -p meilitool ${EXTRA_ARGS}

# Now copy the full repository and build the final binaries.
COPY . .
ARG     COMMIT_SHA
ARG     COMMIT_DATE
ARG     GIT_TAG
ARG     EXTRA_ARGS
ENV     VERGEN_GIT_SHA=${COMMIT_SHA} VERGEN_GIT_COMMIT_TIMESTAMP=${COMMIT_DATE} VERGEN_GIT_DESCRIBE=${GIT_TAG}
ENV     RUSTFLAGS="-C target-feature=-crt-static"
RUN     set -eux; \
        apkArch="$(apk --print-arch)"; \
        cargo build --release -p meilisearch -p meilitool ${EXTRA_ARGS}

# Run image
FROM alpine:3.22
LABEL   org.opencontainers.image.source="https://github.com/meilisearch/meilisearch"

ENV     MEILI_HTTP_ADDR 0.0.0.0:7700
ENV     MEILI_SERVER_PROVIDER docker

RUN     apk add -q --no-cache libgcc tini curl

# copy final binaries from builder stage
COPY    --from=builder /app/target/release/meilisearch /bin/meilisearch
COPY    --from=builder /app/target/release/meilitool /bin/meilitool
RUN     ln -s /bin/meilisearch /meilisearch

WORKDIR /meili_data
EXPOSE  7700/tcp
ENTRYPOINT ["tini", "--"]
CMD     /bin/meilisearch

