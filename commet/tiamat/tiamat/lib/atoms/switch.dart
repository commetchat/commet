import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Default', type: Switch)
Widget wb_switch(BuildContext context) {
  return Center(
      child: material.Padding(
    padding: const EdgeInsets.all(8.0),
    child: Switch(),
  ));
}

@WidgetbookUseCase(name: 'No Icons', type: Switch)
Widget wb_switchNoIcons(BuildContext context) {
  return Center(
      child: material.Padding(
    padding: const EdgeInsets.all(8.0),
    child: Switch(
      offIcon: null,
      onIcon: null,
    ),
  ));
}

class Switch extends StatefulWidget {
  const Switch(
      {super.key, this.onIcon = material.Icons.check, this.offIcon = material.Icons.close, this.defaultState = false});

  final IconData? onIcon;
  final IconData? offIcon;
  final bool defaultState;

  @override
  State<Switch> createState() => _SwitchState();
}

class _SwitchState extends State<Switch> {
  late bool enabled;
  late material.MaterialStateProperty<Icon?> thumbIcon;
  @override
  void initState() {
    super.initState();
    enabled = widget.defaultState;

    thumbIcon = material.MaterialStateProperty.resolveWith<Icon?>(
      (Set<material.MaterialState> states) {
        if (states.contains(material.MaterialState.selected)) {
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
      onChanged: (value) {
        setState(() {
          enabled = value;
        });
      },
      thumbIcon: thumbIcon,
      value: enabled,
      thumbColor: material.MaterialStateProperty.resolveWith(
        (Set<material.MaterialState> states) {
          if (states.contains(material.MaterialState.selected)) {
            return material.Theme.of(context).colorScheme.surface;
          }
          return material.Theme.of(context).colorScheme.secondary;
        },
      ),
    );
  }
}
