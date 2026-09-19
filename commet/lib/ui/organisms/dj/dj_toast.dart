// Short messages from the DJ booth, shown over whatever the user is looking
// at. The app has no Scaffold for a snack bar (see gif_picker.dart), so this
// draws on the root navigator's overlay.
import 'dart:async';

import 'package:commet/main.dart';
import 'package:flutter/material.dart';

class DjToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(String message, {bool isError = false}) {
    final overlay = navigator.currentState?.overlay;
    if (overlay == null) return;
    _dismiss();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 24,
        child: SafeArea(
          child: Center(
            child: _Toast(
                message: message, isError: isError, onClose: _dismiss),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(Duration(seconds: isError ? 7 : 4), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _Toast extends StatelessWidget {
  const _Toast(
      {required this.message, required this.isError, required this.onClose});

  final String message;
  final bool isError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError ? scheme.errorContainer : scheme.inverseSurface;
    final foreground =
        isError ? scheme.onErrorContainer : scheme.onInverseSurface;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: background,
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Icon(isError ? Icons.error_outline_rounded : Icons.album_rounded,
                  size: 18, color: foreground),
              Flexible(
                child: Text(message,
                    style: TextStyle(color: foreground, fontSize: 13)),
              ),
              IconButton(
                tooltip: 'Dismiss',
                iconSize: 16,
                icon: Icon(Icons.close_rounded, color: foreground),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
