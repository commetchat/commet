import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';

class CustomSafeArea extends StatefulWidget {
  const CustomSafeArea({required this.child, super.key});
  final Widget child;

  @override
  State<CustomSafeArea> createState() => _CustomSafeAreaState();
}

class _CustomSafeAreaState extends State<CustomSafeArea> {
  bool isTextFieldFocused = false;

  @override
  void initState() {
    EventBus.onTextFieldFocused.stream.listen(onTextFieldFocused);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (preferences.customOnscreenKeyboardViewOffset.value == 0) {
      return widget.child;
    }

    var query = MediaQuery.of(context);

    return MediaQuery(
        data: query.copyWith(
            viewPadding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                isTextFieldFocused
                    ? preferences.customOnscreenKeyboardViewOffset.value
                    : 0)),
        child: widget.child);
  }

  void onTextFieldFocused(bool event) {
    // Focus events arrive over a stream and can land after this widget is
    // gone (page torn down while a field still had focus).
    if (!mounted) return;
    if (event != isTextFieldFocused) {
      setState(() {
        isTextFieldFocused = event;
      });
    }
  }
}
