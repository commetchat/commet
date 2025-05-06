FROM ubuntu:latest

ARG FLUTTER_VERSION=3.24.4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa \
        ninja-build libgtk-3-dev libolm3 libmpv-dev \
        clang cmake pkg-config liblzma-dev libstdc++-12-dev \
        mpv ffmpeg libmimalloc-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/flutter && \
    curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        | tar -xJf - -C /opt/flutter && \
        git config --global --add safe.directory /opt/flutter/flutter

ENV FLUTTER_HOME=/opt/flutter/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

COPY . /app
WORKDIR /app/commet

RUN flutter config --no-analytics && \
    flutter pub get && \
    dart run scripts/codegen.dart

CMD ["flutter", "run"]