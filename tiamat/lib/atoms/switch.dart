import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Switch)
Widget wbswitch(BuildContext context) {
  return const Center(
      child: material.Padding(
    padding: EdgeInsets.all(8.0),
    child: Switch(),
  ));
}

@UseCase(name: 'No Icons', type: Switch)
Widget wbswitchNoIcons(BuildContext context) {
  return const Center(
      child: material.Padding(
    padding: EdgeInsets.all(8.0),
    child: Switch(
      offIcon: null,
      onIcon: null,
    ),
  ));
}

class Switch extends StatefulWidget {
  const Switch(
      {super.key,
      this.onIcon = material.Icons.check,
      this.offIcon = material.Icons.close,
      this.onChanged,
      this.state = false});

  final IconData? onIcon;
  final IconData? offIcon;
  final bool state;
  final void Function(bool value)? onChanged;

  @override
  State<Switch> createState() => _SwitchState();
}

class _SwitchState extends State<Switch> {
  late material.WidgetStateProperty<Icon?> thumbIcon;
  @override
  void initState() {
    super.initState();
    thumbIcon = material.WidgetStateProperty.resolveWith<Icon?>(
      (Set<material.WidgetState> states) {
        if (states.contains(material.WidgetState.selected)) {
          if (widget.onIcon == null) return null;
          return Icon(widget.onIcon!);
        }
        if (widget.offIcon == null) return null;
        return Icon(widget.offIcon!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return material.Switch(
      onChanged: widget.onChanged,
      thumbIcon: thumbIcon,
      value: widget.state,
      thumbColor: material.WidgetStateProperty.resolveWith(
        (Set<material.WidgetState> states) {
          if (states.contains(material.WidgetState.selected)) {
            return material.Theme.of(context).colorScheme.onPrimary;
          }
          return material.Theme.of(context).colorScheme.secondary;
        },
      ),
    );
  }
}
