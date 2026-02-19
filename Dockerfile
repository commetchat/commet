FROM ghcr.io/cirruslabs/flutter:3.41.1 AS build

RUN sudo apt-get update && sudo apt-get install -y \
    ninja-build \
    libgtk-3-dev \
    libmpv-dev \
    mpv \
    ffmpeg \
    webkit2gtk-4.1

# Rust nightly for vodozemac
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

WORKDIR /app
COPY . .
WORKDIR /app/commet

# Codegen and prepare-web
RUN dart run scripts/codegen.dart
RUN ./scripts/prepare-web.sh

ARG GIT_HASH=unknown
ARG VERSION_TAG=v0.0.0

# Build with flutter web
RUN dart run scripts/build_release.dart --platform web --git_hash $GIT_HASH --version_tag $VERSION_TAG

FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/commet/build/web /usr/share/nginx/html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
