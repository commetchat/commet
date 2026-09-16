// mpv clamps `volume` to `volume-max` (default 130). Normalization boosts
// need more: user 1.5 * gain +18 dB is about 229 on mpv's cubic scale.
// media_kit's web player is an <audio> element with no such property, so
// this file has a web no-op and keeps the media_kit player importable on web
// (the settings previews import it for the volume mapping).
import 'package:media_kit/media_kit.dart';

import 'mpv_volume_max_native.dart'
    if (dart.library.js_interop) 'mpv_volume_max_web.dart' as impl;

/// Raises mpv's volume ceiling for [player] on native; no-op on web.
Future<void> raiseMpvVolumeMax(Player player, double max) =>
    impl.raiseMpvVolumeMax(player, max);
