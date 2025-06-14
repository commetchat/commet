import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SettingsEntryBool extends StatelessWidget {
  const SettingsEntryBool(this.state,
      {required this.title, this.description, this.onChanged, super.key});
  final bool state;
  final String title;
  final String? description;
  final Function(bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.labelEmphasised(title),
              if (description != null) tiamat.Text.labelLow(description!)
            ],
          ),
        ),
        tiamat.Switch(state: state, onChanged: onChanged)
      ],
    );
  }
}
