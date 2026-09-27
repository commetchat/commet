// Whether a capture track has ended. Only the browser ends one on its own
// (device unplugged, permission revoked); desktop WebRTC tracks end when
// the app stops them.
export 'capture_track_state_stub.dart'
    if (dart.library.js_interop) 'capture_track_state_web.dart';
