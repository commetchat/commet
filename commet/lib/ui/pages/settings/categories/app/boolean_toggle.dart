import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class BooleanToggle extends StatefulWidget {
  const BooleanToggle(
      {required this.setValue,
      required this.getValue,
      required this.title,
      this.description,
      this.onChanged,
      super.key});

  final Future<void> Function(bool) setValue;
  final bool Function() getValue;

  final Function(bool)? onChanged;

  final String title;
  final String? description;

  @override
  State<BooleanToggle> createState() => _BooleanToggleState();
}

class _BooleanToggleState extends State<BooleanToggle> {
  late bool state;

  @override
  void initState() {
    state = widget.getValue();
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
              state: state,
              onChanged: (value) async {
                setState(() {
                  state = value;
                });

                try {
                  await widget.setValue(value);
                } catch (_) {}

                await Future.delayed(Duration(milliseconds: 100));

                setState(() {
                  state = widget.getValue();
                });

                widget.onChanged?.call(value);
              },
            ),
          )
        ],
      ),
    );
  }
}
