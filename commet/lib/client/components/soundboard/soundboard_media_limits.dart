// Limits for fetching and holding sound files at playback time. Pure Dart.
//
// A sound's media_uri comes from room state that any Space moderator can set,
// and every participant downloads every sound when joining a call, so the
// import limits (SoundboardConstraints) are enforced again here.
import 'dart:collection';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// A sound file that can never be played: too large, too long, or not audio.
/// Not worth downloading again.
class SoundboardMediaRejected implements Exception {
  final String reason;
  const SoundboardMediaRejected(this.reason);

  @override
  String toString() => 'Sound file rejected: $reason';
}

/// Sends [request] and returns the body, giving up (and cancelling the
/// transfer) as soon as it is known to exceed [maxBytes].
Future<Uint8List> fetchCapped(http.Client client, http.BaseRequest request,
    {required int maxBytes}) async {
  final response = await client.send(request);
  if (response.statusCode != 200) {
    await response.stream.listen(null).cancel();
    throw http.ClientException(
        'Unexpected response: ${response.statusCode}', request.url);
  }

  final declared = response.contentLength;
  if (declared != null && declared > maxBytes) {
    await response.stream.listen(null).cancel();
    throw SoundboardMediaRejected('$declared bytes, over $maxBytes');
  }

  final body = BytesBuilder(copy: false);
  // Leaving the loop by throwing cancels the subscription.
  await for (final chunk in response.stream) {
    if (body.length + chunk.length > maxBytes) {
      throw SoundboardMediaRejected('over $maxBytes bytes');
    }
    body.add(chunk);
  }
  return body.takeBytes();
}

/// Decoded sounds, at most [maxEntries], the least recently played dropped
/// first. A sound whose load failed with [SoundboardMediaRejected] is
/// remembered, so it isn't downloaded again on every trigger; other failures
/// (offline, server error) are retried on the next play.
class SoundboardBufferCache<T> {
  final int maxEntries;
  final LinkedHashMap<String, Future<T>> _entries = LinkedHashMap();
  final Map<String, SoundboardMediaRejected> _rejected = {};

  SoundboardBufferCache({required this.maxEntries});

  /// The decoded sound for [key], loading it with [load] unless it is
  /// already loaded or loading.
  Future<T> get(String key, Future<T> Function() load) {
    final rejected = _rejected[key];
    if (rejected != null) return Future.error(rejected);

    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing;
    }

    final loading = load();
    _entries[key] = loading;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    loading.then<void>((_) {}, onError: (Object error) {
      if (identical(_entries[key], loading)) _entries.remove(key);
      if (error is SoundboardMediaRejected) _rejected[key] = error;
    });
    return loading;
  }

  void clear() {
    _entries.clear();
    _rejected.clear();
  }
}
