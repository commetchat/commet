# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1 — Flutter web builder
# Pre-requisite: commet/assets/vodozemac/ must contain the pre-built WASM
# files (run commet/scripts/prepare-web.sh once, then commit the output).
# ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /build
COPY . .

WORKDIR /build/commet

ARG GIT_HASH=unknown
ARG VERSION_TAG=release
ARG BUILD_DATE=0

RUN flutter pub get
RUN dart run scripts/codegen.dart
RUN flutter build web \
      --dart-define BUILD_MODE=release \
      --dart-define PLATFORM=web \
      --dart-define GIT_HASH=$GIT_HASH \
      --dart-define VERSION_TAG=$VERSION_TAG \
      --dart-define BUILD_DATE=$BUILD_DATE

# ---------------------------------------------------------------------------
# Stage 2 — nginx runtime
# ---------------------------------------------------------------------------
FROM nginx:alpine AS runtime

COPY --from=builder /build/commet/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
