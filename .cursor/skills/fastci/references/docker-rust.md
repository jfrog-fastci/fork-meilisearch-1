# Optimizing Rust Builds in Docker

Building Rust applications in Docker can be slow. Without proper caching, every CI run recompiles the entire dependency tree from scratch, leading to long feedback loops and wasted resources.

## Common Bottlenecks
- **Monolithic Builds**: Copying all source code before running `cargo build` invalidates the Docker layer cache on any code change.
- **Missing Persistent Cache**: GitHub Actions does not natively persist Docker layer caches between runs without explicit configuration.

## Recommended Optimizations

### 1. Cargo-chef Integration
Use `cargo-chef` to split the Rust build process into a "planner" that generates a dependency recipe and a "builder" that compiles only the dependencies. This allows Docker to cache the compiled dependencies in a separate layer.

**Example Dockerfile structure with cargo-chef:**
```dockerfile
# Stage 1: Planner
FROM rust:1.75 AS planner
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# Stage 2: Cacher
FROM rust:1.75 AS cacher
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the cached Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json

# Stage 3: Builder
FROM rust:1.75 AS builder
WORKDIR /app
COPY . .
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
RUN cargo build --release

# Stage 4: Runtime
FROM debian:bookworm-slim
COPY --from=builder /app/target/release/my-app /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/my-app"]
```

### 2. GitHub Actions Cache for Docker
Configure the `docker/build-push-action` to use the `gha` cache backend. Ensure that the Docker layer cache is persisted across different CI runs. A common strategy is to write the cache only on builds that happen on the `main` branch while using it for all other branches.

**Example GitHub Actions Workflow configuration:**
```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: my-registry/my-app:latest
    cache-from: type=gha,scope=my-app-${{matrix.edition}}-${{matrix.platform}}
    cache-to: ${{ github.ref == 'refs/heads/main' && format('type=gha,mode=max,scope=my-app-{0}-{1}', matrix.edition, matrix.platform) || '' }}
```
`