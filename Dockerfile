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

