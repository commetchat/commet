#!/bin/sh -ve

# # Setup vodozemac
git clone https://github.com/famedly/dart-vodozemac.git ../../.vodozemac
cd ../../.vodozemac
git checkout 0.5.0
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release
cd ../commet/commet

rm -f ./assets/vodozemac/vodozemac_bindings_dart*
mv ../../.vodozemac/dart/web/pkg/vodozemac_bindings_dart* ./assets/vodozemac/
rm -rf ../../.vodozemac

# Setup livekit web worker
git clone https://github.com/livekit/client-sdk-flutter.git .livekit
cd .livekit
git checkout ac9d3906eefc8eea91338651b53f4f2d0d2a37cb

SED=$(command -v gsed || command -v sed)
"$SED" -i "s/{'name': 'PBKDF2'.toJS}/{'name': 'HKDF'.toJS}/g" web/e2ee.keyhandler.dart
"$SED" -i "s/getAlgoOptions('PBKDF2', salt)/getAlgoOptions('HKDF', salt)/g" web/e2ee.keyhandler.dart
"$SED" -i "s/{'name': 'PBKDF2'}/{'name': 'HKDF'}/g"           web/e2ee.utils.dart

dart compile js web/e2ee.worker.dart -o ../web/e2ee.worker.dart.js -m
cd ..

rm -rf .livekit