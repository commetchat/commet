import 'package:commet/ui/pages/developer/app_inspector/reflectable_extensions.dart';
import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:flutter/material.dart';
import 'package:reflectable/reflectable.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class FieldInspector extends StatefulWidget {
  const FieldInspector(
      {required this.declaration, required this.instance, super.key});
  final MethodMirror declaration;
  final dynamic instance;
  @override
  State<FieldInspector> createState() => FieldInspectorState();
}

class FieldInspectorState extends State<FieldInspector> {
  dynamic fieldValue;

  @override
  void initState() {
    try {
      final result = ReflectableExtensions.invoke(
          widget.instance, widget.declaration.simpleName);
      fieldValue = result;
    } catch (_) {}

    super.initState();
  }

  static String displayValue(dynamic value) {
    if (value == null) {
      return "null";
    }

    if (value is String) {
      return value;
    }

    try {
      var v = "$value name: ${value.name}";
      return v;
    } catch (_) {}

    try {
      var v = "$value displayname: ${value.displayname}";
      return v;
    } catch (_) {}

    try {
      var v = "$value id: ${value.id}";
      return v;
    } catch (_) {}

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black)
        .withAlpha(7);

    return ExpansionTile(
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: Alignment.topLeft,
      backgroundColor: color,
      dense: true,
      title: Row(
        children: [
          tiamat.Text(widget.declaration.simpleName.toString()),
          const SizedBox(width: 20),
          Flexible(
            child: tiamat.Text.labelLow(
              displayValue(fieldValue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
      children: [buildValue(fieldValue)],
    );
  }

  Widget buildValue(dynamic value, {int index = 0}) {
    if (value == null) {
      return const tiamat.Text("null");
    }

    if (value is List) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value)
            .mapIndexed((e, i) => Container(child: buildValue(e)))
            .toList(),
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.keys.mapIndexed((e, i) {
          var label = displayValue(e);
          if (label == "") {
            label = "\"\"";
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                tiamat.Text.labelLow(
                  "$label:",
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: buildValue(value[e], index: i),
                )
              ],
            ),
          );
        }).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: ValueReflectorWidget(
        value: value,
        index: index,
      ),
    );
  }
}
