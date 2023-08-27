import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Slider)
Widget wbslider(BuildContext context) {
  return const Center(
      child: material.Padding(
    padding: EdgeInsets.all(8.0),
    child: Slider(),
  ));
}

@UseCase(name: 'Divided', type: Slider)
Widget wbsliderDivided(BuildContext context) {
  return const Center(
      child: material.Padding(
    padding: EdgeInsets.all(8.0),
    child: Slider(
      divisions: 5,
    ),
  ));
}

class Slider extends StatefulWidget {
  const Slider({
    super.key,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeStart,
    this.max = 1,
    this.min = 0,
    this.value = 0.5,
    this.divisions,
  });
  final Function(double value)? onChanged;
  final Function(double value)? onChangeEnd;
  final Function(double value)? onChangeStart;
  final double min;
  final double max;
  final int? divisions;
  final double value;

  @override
  State<Slider> createState() => SliderState();
}

class SliderState extends State<Slider> {
  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: material.Colors.transparent,
      child: material.Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        onChanged: (value) {
          widget.onChanged?.call(value);
        },
        onChangeEnd: (value) {
          widget.onChangeEnd?.call(value);
        },
        onChangeStart: (value) {
          widget.onChangeStart?.call(value);
        },
      ),
    );
  }
}
