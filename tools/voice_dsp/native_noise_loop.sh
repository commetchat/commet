#!/usr/bin/env bash
# Linux: noise suppression inside the real WebRTC, end to end.
#
# Makes a PulseAudio microphone for this run only, which plays the noisy
# speech fixture (a null sink fed by paplay, remapped into a source), and
# runs the app's microphone test on it
# (commet/integration_test/voice_dsp/native_noise_test.dart), which also
# kills the app's recording stream mid-capture and checks that the call's
# microphone watch brings it back (pacmd on PulseAudio, pw-cli on
# PipeWire; docs/voice-call-health.md): the fixture
# goes through WebRTC's audio device and processing modules and our hook in
# librust_lib_commet, and is encoded and sent over a local peer connection.
# The test samples WebRTC's own measure of what is encoded and of what is
# decoded; tools/voice_dsp/measure_stats.mjs compares it with the fixture.
#
#   tools/voice_dsp/native_noise_loop.sh
#
# Needs a PulseAudio server (PipeWire's does; a real PulseAudio, like CI's,
# delivers the fixture about a second late, which the measure lines up),
# pactl and paplay, a display for the app window, and what
# `flutter test -d linux` needs. The app runs with its data directories in
# a temporary directory, so the user's own preferences are not touched.
# FLUTTER overrides the flutter binary.
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
flutter=${FLUTTER:-flutter}
fixtures="$repo/target/voice-fixtures"
work=$(mktemp -d "${TMPDIR:-/tmp}/voice-native-loop.XXXXXX")
tag="nsloop$$"
modules=()

cleanup() {
  # Anything still playing into the loop's sinks first: once they are gone
  # PipeWire moves it to the machine's own speakers.
  pkill -f "[p]aplay --device=${tag}_" 2>/dev/null || true
  for m in "${modules[@]}"; do pactl unload-module "$m" 2>/dev/null || true; done
  rm -rf "$work"
}
trap cleanup EXIT

(cd "$repo" && cargo run -q -p audio_dsp --release --example noisy_speech -- "$fixtures")

# A capture device listed before the microphone, which the last test removes
# while the microphone is muted (and a silent one after it, below).
modules+=("$(pactl load-module module-null-sink sink_name="${tag}_before_feed" \
  sink_properties=device.description="${tag}BeforeFeed")")
device_before=$(pactl load-module module-remap-source source_name="${tag}_before" \
  master="${tag}_before_feed.monitor" source_properties=device.description="${tag}Before")
modules+=("$device_before")
modules+=("$(pactl load-module module-null-sink sink_name="${tag}_feed" \
  sink_properties=device.description="${tag}Feed")")
modules+=("$(pactl load-module module-remap-source source_name="${tag}_mic" \
  master="${tag}_feed.monitor" source_properties=device.description="${tag}Mic")")
# Where the app plays, so nothing comes out of the user's speakers.
modules+=("$(pactl load-module module-null-sink sink_name="${tag}_out" \
  sink_properties=device.description="${tag}Out")")
modules+=("$(pactl load-module module-remap-source source_name="${tag}_after" \
  master="${tag}_out.monitor" source_properties=device.description="${tag}After")")

mkdir -p "$work/data" "$work/config" "$work/cache" "$work/results"
volume() { pactl get-source-volume "${tag}_mic" | head -n1 | sed 's/^Volume: //'; }
echo "microphone volume before: $(volume)"
status=0
(
  cd "$repo/commet"
  XDG_DATA_HOME="$work/data" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
    "$flutter" test integration_test/voice_dsp/native_noise_test.dart -d linux \
    --dart-define=NS_LOOP_MIC="${tag}Mic" \
    --dart-define=NS_LOOP_MIC_SINK="${tag}_feed" \
    --dart-define=NS_LOOP_FIXTURE="$fixtures/noisy_speech_48k.wav" \
    --dart-define=NS_LOOP_ROOM_NOISE="$fixtures/room_noise_48k.wav" \
    --dart-define=NS_LOOP_RESULTS="$work/results" \
    --dart-define=NS_LOOP_CAPTURE="${NS_LOOP_CAPTURE:-}" \
    --dart-define=NS_LOOP_OUT="${tag}Out" \
    --dart-define=NS_LOOP_MONITOR="${NS_LOOP_MONITOR:-false}" \
    --dart-define=NS_LOOP_DEVICE_BEFORE="$device_before"
) || status=$?

echo "microphone volume after: $(volume)"
if [ -n "${NS_LOOP_KEEP:-}" ]; then
  mkdir -p "$NS_LOOP_KEEP" && cp "$work"/results/* "$NS_LOOP_KEEP"/ 2>/dev/null || true
  echo "results kept in $NS_LOOP_KEEP"
fi
if [ "$status" != 0 ]; then
  echo "the app side of the loop failed (see above)"
  exit "$status"
fi
echo "DSP report (rate frames flags): $(cat "$work/results/report.txt")"
echo "A recording that died mid-call: $(cat "$work/results/recording_died.txt")"
echo "WebRTC processing of the microphone around a custom audio source: $(cat "$work/results/custom_source.txt")"
node "$repo/tools/voice_dsp/measure_stats.mjs" "$work/results"
