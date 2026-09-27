#!/usr/bin/env bash
# Noise suppression in the browser, as CI checks it (ci.yml, voice-dsp):
#
# 1. the contracts between Rust, Dart, C++ and JS (check_contracts.py);
# 2. the web app builds, with audio_dsp.wasm built first
#    (commet/scripts/build-audio-dsp-wasm.sh), and the build carries it;
# 3. a noisy recording through that build's own audio_dsp.js, worklet and
#    wasm in Chrome (web_noise_loop.mjs);
# 4. the same through the web app's own Dart and the vendored LiveKit, a
#    microphone restart and a legacy 1:1 call (web_noise_loop.mjs --app);
# 5. the DSP keeps the microphone going out when its own worker traps or
#    hangs and when the browser suspends its audio context
#    (web_health_loop.mjs, docs/voice-call-health.md).
#
#   tools/voice_dsp/web_loops.sh
#
# Needs cargo with the wasm32-unknown-unknown target, flutter, node (22 or
# later) and Chrome (CHROME, or google-chrome-stable on PATH). FLUTTER
# overrides the flutter binary.
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
flutter=${FLUTTER:-flutter}
chrome=${CHROME:-google-chrome-stable}

cd "$repo"
python3 tools/voice_dsp/check_contracts.py

cd "$repo/commet"
scripts/build-audio-dsp-wasm.sh
node "$repo/tools/voice_dsp/web_health_loop.mjs" --web-root "$repo/commet/web" --chrome "$chrome"
# A second web build into another directory reuses the first one's "copy
# web/" step as up to date and leaves audio_dsp.* out: every build starts
# from a clean build cache.
rm -rf .dart_tool/flutter_build
"$flutter" build web --release --dart-define PLATFORM=web
python3 "$repo/tools/voice_dsp/check_contracts.py" --web-build "$repo/commet/build/web"
node "$repo/tools/voice_dsp/web_noise_loop.mjs" --web-root commet/build/web --chrome "$chrome"

rm -rf .dart_tool/flutter_build
"$flutter" build web --release -t integration_test/voice_dsp/web_noise_main.dart \
  --dart-define PLATFORM=web -o "$repo/commet/build/web_noise_loop"
node "$repo/tools/voice_dsp/web_noise_loop.mjs" --app commet/build/web_noise_loop --chrome "$chrome"
