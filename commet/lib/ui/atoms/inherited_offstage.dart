import 'package:flutter/material.dart';

class InheritedOffstage extends InheritedWidget {
  const InheritedOffstage(
      {required this.offstage, super.key, required super.child});

  final bool offstage;

  static InheritedOffstage? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedOffstage>();
  }

  static bool isOffstage(BuildContext context) {
    final InheritedOffstage? result = maybeOf(context);
    return result?.offstage ?? false;
  }

  @override
  bool updateShouldNotify(covariant InheritedOffstage oldWidget) {
    return oldWidget.offstage != offstage;
  }
}
