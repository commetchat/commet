import 'dart:async';

import 'package:commet/debug/log.dart';
import 'package:flutter/widgets.dart';

class AppFocus {
  static StreamController _focusStateChanged = StreamController.broadcast();

  static Stream<void> get focusStateChanged => _focusStateChanged.stream;

  static AppLifecycleState? _state = AppLifecycleState.inactive;

  static bool get focused => _state == AppLifecycleState.resumed;

  static void init() {
    _state = WidgetsBinding.instance.lifecycleState;

    WidgetsBinding.instance.addObserver(AppFocusObserver((state) {
      Log.i("App lifecycle state changed: ${state}");

      _state = state;
      _focusStateChanged.add(null);
    }));
  }
}

class AppFocusObserver extends WidgetsBindingObserver {
  final Function(AppLifecycleState state) onStateChanged;

  AppFocusObserver(this.onStateChanged);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
