// The booth's questions to the user: whether to download what DJing needs
// (yt-dlp and Deno, nothing fetched without a yes), and whether to take the
// decks someone is handing them.
import 'dart:async';

import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/dj/dj_toast.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

Future<bool>? _asking;

/// True once this client has what DJing needs. Several callers at once share
/// one prompt.
Future<bool> ensureDjTools() =>
    _asking ??= _ensure().whenComplete(() => _asking = null);

Future<bool> _ensure() async {
  // Looking for the programs can take a few seconds the first time.
  final slow = Timer(const Duration(milliseconds: 400),
      () => DjToast.show('Checking the DJ tools…'));
  final DjToolsCheck? check;
  try {
    check = await DjPlatform.instance.checkTools();
  } finally {
    slow.cancel();
  }
  if (check == null) return true;

  final context = navigator.currentContext;
  if (context == null || !context.mounted) return false;
  final list = check.missing.map((m) => '**${m.$1}** (${m.$2})').join(' and ');
  final yes = await AdaptiveDialog.confirmation(
    context,
    title: 'Set up the DJ decks',
    prompt: 'To play songs from YouTube, SoundCloud and Spotify, Roscord uses '
        '$list. They are downloaded once, from their official GitHub '
        'releases, into Roscord\'s data folder.',
    confirmationText: 'Download',
    cancelText: 'Not now',
  );
  if (yes != true || !context.mounted) return false;

  final progress = ValueNotifier<(String, double?)>(('', null));
  final cancel = DjToolsCancel();
  final done = Completer<void>();
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      done.future.whenComplete(() {
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      });
      return AlertDialog(
        title: const Text('Setting up the DJ decks'),
        content: ValueListenableBuilder(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              tiamat.Text.labelLow(value.$1.isEmpty
                  ? 'Starting…'
                  : 'Downloading ${value.$1}…'),
              LinearProgressIndicator(value: value.$2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: cancel.cancel, child: const Text('Cancel')),
        ],
      );
    },
  ));

  try {
    await DjPlatform.instance.installTools(
        cancel: cancel,
        onProgress: (step, value) => progress.value = (step, value));
    done.complete();
    return true;
  } on DjToolsCancelled {
    done.complete();
    return false;
  } catch (e, s) {
    Log.onError(e, s, content: 'DJ booth: could not download the tools');
    done.complete();
    DjToast.show("Couldn't set up the DJ decks: $e", isError: true);
    return false;
  }
}

/// Asks whether to take the decks [fromName] is handing over, for someone
/// who didn't ask for them. Unanswered for long, it counts as a no.
Future<bool> askToTakeDecks(String fromName) async {
  final context = navigator.currentContext;
  if (context == null || !context.mounted) return false;
  final answer = await AdaptiveDialog.confirmation(
    context,
    title: '$fromName is handing you the decks',
    prompt: 'Take over as the DJ? The music keeps playing and the queue '
        'stays as it is.',
    confirmationText: 'Take the decks',
    cancelText: 'No thanks',
  ).timeout(const Duration(seconds: 60), onTimeout: () {
    final open = navigator.currentContext;
    if (open != null && open.mounted) Navigator.of(open).maybePop();
    return false;
  });
  return answer == true;
}
