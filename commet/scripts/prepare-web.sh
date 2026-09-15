#!/bin/sh -ve

# # Setup vodozemac
git clone https://github.com/famedly/dart-vodozemac.git .vodozemac
cd .vodozemac
git checkout 0.5.0
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release
cd ..
rm -f ./assets/vodozemac/vodozemac_bindings_dart*
mv .vodozemac/dart/web/pkg/vodozemac_bindings_dart* ./assets/vodozemac/
rm -rf .vodozemac

# Setup livekit web worker from the vendored copy (third_party/README.md)
(cd ../third_party/livekit-client-sdk-flutter && dart pub get && \
  dart compile js web/e2ee.worker.dart -o ../../commet/web/e2ee.worker.dart.js -m)

# Build the voice DSP (rust/audio_dsp) to WebAssembly for the AudioWorklet.
# Needs `rustup target add wasm32-unknown-unknown`. If cargo is not on PATH
# but docker is, the build runs in the official rust image.
if command -v cargo >/dev/null 2>&1; then
  (cd .. && cargo build -p audio_dsp --release --target wasm32-unknown-unknown)
else
  docker run --rm -v "$(readlink -f ..)":/w -w /w rust:1 \
    sh -c 'rustup target add wasm32-unknown-unknown >/dev/null && cargo build -p audio_dsp --release --target wasm32-unknown-unknown && chown -R '"$(id -u):$(id -g)"' /w/target'
fi
cp ../target/wasm32-unknown-unknown/release/audio_dsp.wasm ./web/audio_dsp.wasm
