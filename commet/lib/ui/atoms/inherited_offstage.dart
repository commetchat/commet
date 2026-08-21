import 'package:flutter/material.dart';

class InheritedOffstage extends InheritedWidget {
  const InheritedOffstage(
      {required this.offstage, super.key, required super.child});

  final bool offstage;

  static InheritedOffstage? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedOffstage>();
  }

  static InheritedOffstage of(BuildContext context) {
    final InheritedOffstage? result = maybeOf(context);
    return result!;
  }

  @override
  bool updateShouldNotify(covariant InheritedOffstage oldWidget) {
    return oldWidget.offstage != offstage;
  }
}
