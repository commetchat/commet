/// Orders the writes to one device's call membership state event.
///
/// Hanging up clears the membership, and that request can still be in flight,
/// or be retried by the SDK, when the user rejoins. The late clear would then
/// erase the new membership and leave them in the call but invisible to
/// everyone, with the LIVE badge gone (issue #48).
class CallMembershipWrites {
  CallMembershipWrites._();

  static final Map<String, Future<void>> _pending = {};

  /// Registers a clear of [stateKey] that later writes have to wait for.
  /// Returns [write] unchanged, so the caller still sees its result.
  static Future<T> clearing<T>(String stateKey, Future<T> write) {
    // Never fails: waiting for this only orders the writes, the caller deals
    // with the error.
    final done = write.then<void>((_) {}, onError: (_) {});
    _pending[stateKey] = done;
    done.whenComplete(() {
      if (identical(_pending[stateKey], done)) _pending.remove(stateKey);
    });
    return write;
  }

  /// Waits for a clear of [stateKey] that is still in flight. Bounded: a
  /// request that never lands must not stop the user from joining.
  static Future<void> settled(String stateKey,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final pending = _pending[stateKey];
    if (pending == null) return;
    try {
      await pending.timeout(timeout);
    } catch (_) {
      // Logged where the clear was issued.
    }
  }
}
