# This file was generated using a Jinja2 template.
# Please make your changes in `Dockerfile.j2` and then `make` the individual Dockerfiles.

# Using multistage build:
# 	https://docs.docker.com/develop/develop-images/multistage-build/
# 	https://whitfin.io/speeding-up-rust-docker-builds/
####################### VAULT BUILD IMAGE  #######################
# The web-vault digest specifies a particular web-vault build on Docker Hub.
# Using the digest instead of the tag name provides better security,
# as the digest of an image is immutable, whereas a tag name can later
# be changed to point to a malicious image.
#
# To verify the current digest for a given tag name:
# - From https://hub.docker.com/r/bitwardenrs/web-vault/tags,
#   click the tag name to view the digest of the image it currently points to.
# - From the command line:
#     $ docker pull bitwardenrs/web-vault:v2.18.2
#     $ docker image inspect --format "{{.RepoDigests}}" bitwardenrs/web-vault:v2.18.2
#     [bitwardenrs/web-vault@sha256:c287301264c7dc86d89aa80487fd7960cc24048390d2bef9ef910dfc77d2c7d5]
#
# - Conversely, to get the tag name from the digest:
#     $ docker image inspect --format "{{.RepoTags}}" bitwardenrs/web-vault@sha256:c287301264c7dc86d89aa80487fd7960cc24048390d2bef9ef910dfc77d2c7d5
#     [bitwardenrs/web-vault:v2.18.2]
#
FROM bitwardenrs/web-vault@sha256:c287301264c7dc86d89aa80487fd7960cc24048390d2bef9ef910dfc77d2c7d5 as vault

########################## BUILD IMAGE  ##########################
FROM rust:latest as build

# Debian-based builds support multidb
ARG DB=sqlite,mysql,postgresql

# Build time options to avoid dpkg warnings and help with reproducible builds.
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=UTC TERM=xterm-256color

# Don't download rust docs
RUN rustup set profile minimal

# Install DB packages
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    libmariadb-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Creates a dummy project used to grab dependencies
RUN USER=root cargo new --bin /app
WORKDIR /app

# Copies over *only* your manifests and build files
COPY ./Cargo.* ./
COPY ./rust-toolchain ./rust-toolchain
COPY ./build.rs ./build.rs


# Builds your dependencies and removes the
# dummy project, except the target folder
# This folder contains the compiled dependencies
RUN cargo build --features ${DB} --release
RUN find . -not -path "./target*" -delete

# Copies the complete project
# To avoid copying unneeded files, use .dockerignore
COPY . .

# Make sure that we actually build the project
RUN touch src/main.rs

# Builds again, this time it'll just be
# your actual source files being built
RUN cargo build --features ${DB} --release

######################## RUNTIME IMAGE  ########################
# Create a new stage with a minimal image
# because we already have a binary built
FROM debian:buster-slim

ENV ROCKET_ENV "staging"
ENV ROCKET_PORT=80
ENV ROCKET_WORKERS=10

# Install needed libraries
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    openssl \
    ca-certificates \
    curl \
    supervisor \
    sqlite3 \
    nano \
    libmariadb-dev-compat \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && curl -s -O https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb \
    && dpkg -i cloudflared-stable-linux-amd64.deb \
    && rm cloudflared-stable-linux-amd64.deb
    
RUN mkdir /data
VOLUME /data
EXPOSE 80
EXPOSE 3012

# Copies the files from the context (Rocket.toml file and web-vault)
# and the binary from the "build" stage to the current stage
COPY Rocket.toml .
COPY --from=vault /web-vault ./web-vault
COPY --from=build /app/target/release/bitwarden_rs .

COPY docker/healthcheck.sh /healthcheck.sh
COPY docker/start.sh /start.sh
COPY supervisord.conf /etc/supervisord.conf
COPY argo-tunnel.sh /usr/share/argo-tunnel.sh
RUN chmod +x /usr/share/argo-tunnel.sh

HEALTHCHECK --interval=60s --timeout=10s CMD ["/healthcheck.sh"]

# Configures the startup!
#WORKDIR /
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
