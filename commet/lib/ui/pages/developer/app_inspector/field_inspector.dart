import 'package:commet/client/matrix/matrix_client.dart';
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
      var v = "name: ${value.name}";
      return v;
    } catch (_) {}

    try {
      var v = "displayname: ${value.displayname}";
      return v;
    } catch (_) {}

    try {
      var v = "id: ${value.id}";
      return v;
    } catch (_) {}

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: Alignment.topLeft,
      dense: true,
      title: Row(
        children: [
          tiamat.Text(widget.declaration.simpleName.toString()),
          SizedBox(width: 20),
          tiamat.Text.labelLow(displayValue(fieldValue))
        ],
      ),
      children: [
        tiamat.Tile.low(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
          child: buildValue(fieldValue),
        ))
      ],
    );
  }

  Widget buildValue(dynamic value) {
    print("Building value: ${value}");

    if (value == null) {
      return tiamat.Text("null");
    }

    if (value is List) {
      return Column(
        children: (value as List).map((e) => buildValue(e)).toList(),
      );
    }

    return ValueReflectorWidget(value: value);
  }
}
