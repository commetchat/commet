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
FROM nginx:1.28-alpine AS olm-build-env

RUN apk add --no-cache --update alpine-sdk cmake && \
    git clone https://gitlab.matrix.org/matrix-org/olm.git && \
    cd olm && git checkout 7e0c8277032e40308987257b711b38af8d77cc69 && \
    cmake -DCMAKE_BUILD_TYPE=Release . -Bbuild && \
    cmake --build build --config Release

# Stage 3
FROM nginx:1.28-alpine
COPY --from=build-env /app/commet/build/web /usr/share/nginx/html
COPY --from=olm-build-env /usr/local/lib/libolm.so.3.2.16 /usr/local/lib/libolm.so.3.2.16
RUN ln -sf libolm.so.3.2.16 /usr/local/lib/libolm.so.3 && \
    ln -sf libolm.so.3.2.16 /usr/local/lib/libolm.so