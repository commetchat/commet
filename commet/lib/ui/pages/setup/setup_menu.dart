import 'package:flutter/material.dart';

enum SetupMenuState {
  canProgress,
  cannotProgress,
}

abstract class SetupMenu {
  Widget builder(BuildContext context);

  SetupMenuState get state;

  Stream<SetupMenuState> get onStateChanged;

  Future<void> submit();
}
