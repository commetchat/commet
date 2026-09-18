#!/bin/sh
# Downloads the source recordings the fixtures in this directory are built
# from. The fixtures themselves are committed, so this is only needed to
# rebuild them (see README.md):
#
#   sh testdata/fetch_sources.sh && cargo run -p audio_dsp --example make_fixtures
#
# Source: the CMU_ARCTIC databases (Carnegie Mellon University, Language
# Technologies Institute), 16 kHz mono, distributed under a free licence
# permitting unrestricted use with attribution. http://festvox.org/cmu_arctic/
set -e
dir=$(dirname "$0")/sources
mkdir -p "$dir"
base=http://festvox.org/cmu_arctic/cmu_arctic

# bdl: US male, stands in for the local speaker (the user talking).
# slt: US female, stands in for dialogue coming out of the speakers.
# clb: US female, stands in for a remote participant on playout.
for voice in bdl slt clb; do
  for n in 0001 0002 0003 0004 0005 0006; do
    f="$dir/${voice}_a${n}.wav"
    [ -f "$f" ] || curl -sSf -o "$f" "$base/cmu_us_${voice}_arctic/wav/arctic_a${n}.wav"
  done
done
echo "sources in $dir"
