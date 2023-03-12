import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Default', type: Slider)
Widget wb_slider(BuildContext context) {
  return Center(
      child: material.Padding(
    padding: const EdgeInsets.all(8.0),
    child: Slider(),
  ));
}

@WidgetbookUseCase(name: 'Divided', type: Slider)
Widget wb_sliderDivided(BuildContext context) {
  return Center(
      child: material.Padding(
    padding: const EdgeInsets.all(8.0),
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
    this.divisions,
  });
  final Function(double value)? onChanged;
  final Function(double value)? onChangeEnd;
  final Function(double value)? onChangeStart;
  final double min;
  final double max;
  final int? divisions;

  @override
  State<Slider> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  double value = 0;

  @override
  Widget build(BuildContext context) {
    return material.Slider(
      value: value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
        widget.onChanged?.call(value);
      },
      onChangeEnd: (value) {
        widget.onChangeEnd?.call(value);
      },
      onChangeStart: (value) {
        widget.onChangeStart?.call(value);
      },
    );
  }
}
