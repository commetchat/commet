import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class FocusNodeMonitor extends StatefulWidget {
  const FocusNodeMonitor({required this.child, super.key});
  final Widget child;

  @override
  State<FocusNodeMonitor> createState() => _FocusNodeMonitorState();
}

class _FocusNodeMonitorState extends State<FocusNodeMonitor> {
  @override
  void initState() {
    FocusManager.instance.addListener(onFocusChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void onFocusChanged() {
    var focus = FocusManager.instance.primaryFocus;
    bool isText = isEditableTextFocused(focus);
    EventBus.onTextFieldFocused.add(isText);
  }

  bool isEditableTextFocused(FocusNode? focus) {
    if (focus?.context?.widget case Focus widget) {
      if (widget.child case NotificationListener listener) {
        if (listener.child case Scrollable scrollable) {
          if (scrollable.restorationId == "editable") {
            return true;
          }
        }
      }
    }

    return false;
  }
}
