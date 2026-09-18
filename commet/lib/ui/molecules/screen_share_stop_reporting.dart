import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Stops [session]'s screen share and tells the user when the stop did not
/// end it.
///
/// The stop control lives on two surfaces — the voice panel's live preview
/// and the call view — and the tiamat buttons that host them call their
/// callback as a bare [Function] without awaiting it. Both surfaces go through
/// this helper so the callback can own its async error handling and the two
/// cannot drift (issue #67): a stop that throws, or that comes back with the
/// share still live, shows a message instead of failing silently or surfacing
/// as an unhandled async error.
Future<void> stopScreenshareOrReportFailure(
    BuildContext context, VoipSession session) async {
  // Looked up before the await: the stop can outlive the surface that asked
  // for it, and looking an ancestor up on a disposed context would throw.
  final messenger = context.mounted ? ScaffoldMessenger.maybeOf(context) : null;

  try {
    await session.stopScreenshare();
  } catch (e, s) {
    Log.onError(e, s, content: "Could not stop the screen share");
    _reportStopFailed(messenger);
    return;
  }

  // The livekit session verifies its own stop (issue #63); this covers any
  // session that returns while the capture keeps running, so a failed stop is
  // never reported as a silent success.
  if (session.isSharingScreen) {
    Log.w("The screen share still looks live after a stop");
    _reportStopFailed(messenger);
  }
}

void _reportStopFailed(ScaffoldMessengerState? messenger) {
  // A messenger that went away with the app has no user left to tell, and
  // showing a SnackBar on a disposed one would throw.
  if (messenger == null || !messenger.mounted) return;
  messenger.showSnackBar(SnackBar(content: Text(messageStopScreenshareFailed)));
}

String get messageStopScreenshareFailed => Intl.message(
    "Could not stop sharing your screen. Try again, or leave the call.",
    name: "messageStopScreenshareFailed",
    desc: "Shown when stopping a screen share did not end the share");
