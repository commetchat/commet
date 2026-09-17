// Synthetic MP3 data for soundboard tests: silent frames with real headers.

const _mpeg1Layer3Kbps = [
  0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, //
];

/// [count] silent MPEG-1 Layer III stereo frames at 44.1 kHz.
List<int> mpeg1Frames(int count, {int kbps = 128}) {
  final length = 144 * kbps * 1000 ~/ 44100;
  final frame = List<int>.filled(length, 0);
  frame.setAll(0, [0xFF, 0xFB, _mpeg1Layer3Kbps.indexOf(kbps) << 4, 0x00]);
  return [for (var i = 0; i < count; i++) ...frame];
}

/// An ID3v2.4 tag whose body is [bodyLength] bytes (e.g. cover art).
List<int> id3v2(int bodyLength) => [
      ...'ID3'.codeUnits,
      4,
      0,
      0,
      bodyLength >> 21 & 0x7F,
      bodyLength >> 14 & 0x7F,
      bodyLength >> 7 & 0x7F,
      bodyLength & 0x7F,
      ...List.filled(bodyLength, 0xFF),
    ];

/// Duration of [frames] frames, rounded like Mp3Duration.
int framesToMs(int frames, {int samplesPerFrame = 1152, int rate = 44100}) =>
    (frames * samplesPerFrame * 1000 / rate).round();
