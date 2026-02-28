import 'package:commet/config/preferences/bool_preference.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class BooleanPreferenceToggle extends StatefulWidget {
  const BooleanPreferenceToggle(
      {required this.preference,
      required this.title,
      this.description,
      this.onChanged,
      super.key});
  final BoolPreference preference;
  final Function(bool)? onChanged;

  final String title;
  final String? description;

  @override
  State<BooleanPreferenceToggle> createState() =>
      _BooleanPreferenceToggleState();
}

class _BooleanPreferenceToggleState extends State<BooleanPreferenceToggle> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelEmphasised(widget.title),
                if (widget.description != null)
                  tiamat.Text.labelLow(widget.description!)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            child: tiamat.Switch(
              state: widget.preference.value,
              onChanged: (value) async {
                await widget.preference.set(value);
                setState(() {});
                widget.onChanged?.call(value);
              },
            ),
          )
        ],
      ),
    );
  }
}

class NullableBooleanPreferenceToggle extends StatefulWidget {
  const NullableBooleanPreferenceToggle(
      {required this.preference,
      required this.title,
      this.description,
      super.key});
  final NullableBoolPreference preference;

  final String title;
  final String? description;

  @override
  State<NullableBooleanPreferenceToggle> createState() =>
      _NullableBooleanPreferenceToggleState();
}

class _NullableBooleanPreferenceToggleState
    extends State<NullableBooleanPreferenceToggle> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.labelEmphasised(widget.title),
              if (widget.description != null)
                tiamat.Text.labelLow(widget.description!)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: tiamat.Switch(
            state: widget.preference.value ?? false,
            onChanged: (value) async {
              await widget.preference.set(value);
              setState(() {});
            },
          ),
        )
      ],
    );
  }
}
