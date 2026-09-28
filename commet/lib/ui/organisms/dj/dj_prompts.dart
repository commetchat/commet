// The booth's questions to the user: installing a source extension (from a
// file or a link, nothing fetched without a yes; docs/dj-extensions.md), and
// whether to take the decks someone is handing them.
import 'dart:async';

import 'package:commet/client/matrix/components/dj/dj_platform.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/dj/dj_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

Future<void>? _installing;

/// Asks for a source extension (a file or a link; [link] skips asking, to
/// update one from where it came), shows what it is and what it downloads,
/// and installs it once the user agrees. One at a time.
Future<void> installDjSource(BuildContext context, {String? link}) =>
    _installing ??=
        _install(context, link).whenComplete(() => _installing = null);

Future<void> _install(BuildContext context, String? link) async {
  final sources = DjPlatform.instance.sources;
  if (sources == null) return;

  final choice = link != null
      ? _SourceChoice(link: link)
      : await showDialog<_SourceChoice>(
          context: context, builder: (_) => const _ChooseSourceDialog());
  if (choice == null || !context.mounted) return;

  final DjSourcePackage package;
  try {
    final opened = await _withProgress<DjSourcePackage>(
        context,
        'Reading the extension',
        (onProgress, cancel) => choice.file != null
            ? sources.openFile(choice.file!)
            : sources.openLink(choice.link!, cancel: cancel));
    if (opened == null) return;
    package = opened;
  } catch (e, s) {
    Log.onError(e, s, content: 'DJ booth: could not read an extension');
    DjToast.show("Couldn't read that extension: $e", isError: true);
    return;
  }
  if (!context.mounted) return;

  final info = package.info;
  final problem = package.problem;
  if (problem != null) {
    DjToast.show("${info.name} can't be installed here: $problem",
        isError: true);
    return;
  }
  final downloads = package.downloads
      .map((d) => d.$2 == null ? '**${d.$1}**' : '**${d.$1}** (${d.$2})')
      .join(', ');
  final replacing = sources.installed.value
      .where((installed) => installed.id == info.id)
      .firstOrNull;
  final yes = await AdaptiveDialog.confirmation(
    context,
    title: replacing == null
        ? 'Install ${info.name} ${info.version}?'
        : 'Replace ${info.name} ${replacing.version} with ${info.version}?',
    prompt: [
      if (info.description != null) info.description!,
      if (info.homepage != null) info.homepage!,
      'A source extension runs a program on your computer, with your '
          'permissions. It is not made by Roscord\'s makers: install it only '
          'if you trust where it came from, and use it within the terms of '
          'the sites it plays from.',
      if (downloads.isNotEmpty) 'It downloads $downloads.',
    ].join('\n\n'),
    confirmationText: 'Install',
    cancelText: 'Cancel',
  );
  if (yes != true || !context.mounted) return;

  try {
    final done = await _withProgress<bool>(context, 'Installing ${info.name}',
        (onProgress, cancel) async {
      await sources.install(package, onProgress: onProgress, cancel: cancel);
      return true;
    });
    if (done == true) DjToast.show('${info.name} is installed');
  } catch (e, s) {
    Log.onError(e, s, content: 'DJ booth: could not install an extension');
    DjToast.show("Couldn't install ${info.name}: $e", isError: true);
  }
}

class _SourceChoice {
  final String? file;
  final String? link;

  const _SourceChoice({this.file, this.link});
}

class _ChooseSourceDialog extends StatefulWidget {
  const _ChooseSourceDialog();

  @override
  State<_ChooseSourceDialog> createState() => _ChooseSourceDialogState();
}

class _ChooseSourceDialogState extends State<_ChooseSourceDialog> {
  final TextEditingController _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _linkOk => Uri.tryParse(_link.text.trim())?.scheme == 'https';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a source extension',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = result?.files.singleOrNull?.path;
    if (path != null && mounted) {
      Navigator.of(context).pop(_SourceChoice(file: path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a music source'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            tiamat.Text.labelLow(
                'A source extension lets the DJ play songs from links. '
                'Extensions are made by others and come as a .zip: open '
                'the file, or paste a link to it.'),
            TextField(
              controller: _link,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_linkOk) {
                  Navigator.of(context)
                      .pop(_SourceChoice(link: _link.text.trim()));
                }
              },
              decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Link to the extension',
                  hintText: 'https://…/extension.zip'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _pickFile, child: const Text('Open a file…')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _linkOk
              ? () => Navigator.of(context)
                  .pop(_SourceChoice(link: _link.text.trim()))
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

/// Runs [task] under a dialog showing its progress, with a Cancel button.
/// Null when the user cancelled.
Future<T?> _withProgress<T>(
    BuildContext context,
    String title,
    Future<T> Function(void Function(String step, double? progress) onProgress,
            DjSourceCancel cancel)
        task) async {
  final progress = ValueNotifier<(String, double?)>(('', null));
  final cancel = DjSourceCancel();
  final done = Completer<void>();
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      done.future.whenComplete(() {
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      });
      return AlertDialog(
        title: Text(title),
        content: ValueListenableBuilder(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              tiamat.Text.labelLow(
                  value.$1.isEmpty ? 'Starting…' : 'Downloading ${value.$1}…'),
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
    return await task((step, value) => progress.value = (step, value), cancel);
  } on DjSourceCancelled {
    return null;
  } catch (_) {
    if (cancel.cancelled) return null;
    rethrow;
  } finally {
    done.complete();
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
