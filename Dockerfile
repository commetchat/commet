# Stage 1
FROM ubuntu:latest AS build-env

ARG FLUTTER_VERSION=3.24.4

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/flutter/flutter/bin:${PATH}"

RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa \
        ninja-build libgtk-3-dev libolm3 libmpv-dev \
        clang cmake pkg-config liblzma-dev libstdc++-12-dev \
        mpv ffmpeg libmimalloc-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/flutter && \
    curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        | tar -xJf - -C /opt/flutter && \
        git config --global --add safe.directory /opt/flutter/flutter && \
        flutter config --no-analytics && \
        flutter config --no-cli-animations && \
        useradd -ms /bin/bash commet && \
        chown -R commet:commet /opt/flutter

COPY . /app
RUN chown -R commet:commet /app
WORKDIR /app/commet
USER commet

RUN flutter pub get && \
    dart run scripts/codegen.dart && \
    flutter build web

# Stage 2
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/commet/build/web /usr/share/nginx/html