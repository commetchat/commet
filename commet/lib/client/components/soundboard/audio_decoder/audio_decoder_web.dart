import 'dart:js_interop';
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';
import 'package:commet/debug/log.dart';
import 'package:web/web.dart' as web;

Future<PcmAudio?> decode(Uint8List bytes, String mimeType) async {
  try {
    // An offline context decodes without opening an audio device. It
    // resamples to its own rate, which does not change loudness.
    final ctx = web.OfflineAudioContext(
        web.OfflineAudioContextOptions(length: 1, sampleRate: 48000));
    // decodeAudioData detaches the buffer it gets; hand it a copy.
    final copy = Uint8List.fromList(bytes).buffer.toJS;
    final buffer = await ctx.decodeAudioData(copy).toDart;
    return PcmAudio(
      sampleRate: buffer.sampleRate.round(),
      channels: [
        for (var c = 0; c < buffer.numberOfChannels; c++)
          buffer.getChannelData(c).toDart,
      ],
    );
  } catch (e) {
    Log.w('Soundboard decoder: browser could not decode $mimeType: $e');
    return null;
  }
}
