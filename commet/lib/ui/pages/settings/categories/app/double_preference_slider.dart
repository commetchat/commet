import 'package:commet/config/preferences/double_preference.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class DoublePreferenceSlider extends StatefulWidget {
  const DoublePreferenceSlider(
      {required this.preference,
      required this.min,
      required this.max,
      required this.title,
      this.units,
      this.description,
      this.numDecimals = 1,
      this.onChanged,
      super.key});

  final DoublePreference preference;
  final Function(double)? onChanged;
  final String? units;

  final double min;
  final double max;
  final int numDecimals;
  final String title;
  final String? description;

  @override
  State<DoublePreferenceSlider> createState() => _DoublePreferenceSliderState();
}

class _DoublePreferenceSliderState extends State<DoublePreferenceSlider> {
  late double value;

  @override
  void initState() {
    value = widget.preference.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceContainer.withAlpha(100),
          border: BoxBorder.all(
              color: ColorScheme.of(context).secondary.withAlpha(20)),
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tiamat.Text(widget.title),
            if (widget.description != null)
              tiamat.Text.labelLow(widget.description!),
            Row(
              children: [
                tiamat.Text.labelLow(
                    "${value.toStringAsFixed(widget.numDecimals)}${widget.units ?? ""}"),
                Expanded(
                  child: tiamat.Slider(
                    value: value,
                    min: widget.min,
                    max: widget.max,
                    onChanged: (newValue) {
                      var strValue =
                          newValue.toStringAsFixed(widget.numDecimals);
                      var finalValue = double.parse(strValue);
                      setState(() {
                        value = finalValue;
                        widget.preference.set(finalValue);
                      });
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
