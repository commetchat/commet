import 'package:commet/main.reflectable.dart';
import 'package:commet/ui/pages/developer/app_inspector/app_inspector_page.dart';
import 'package:commet/ui/pages/developer/app_inspector/field_inspector.dart';
import 'package:commet/ui/pages/developer/app_inspector/reflectable_matrix_client.dart';
import 'package:flutter/material.dart';
import 'package:reflectable/reflectable.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:matrix/matrix.dart' as matrix;

class Reflector extends Reflectable {
  const Reflector()
      : super(typingCapability, invokingCapability,
            libraryDependenciesCapability);
}

const reflector = const Reflector();

class ValueReflectorWidget extends StatefulWidget {
  const ValueReflectorWidget({required this.value, super.key});
  final dynamic value;

  @override
  State<ValueReflectorWidget> createState() => _ValueReflectorWidgetState();
}

class _ValueReflectorWidgetState extends State<ValueReflectorWidget> {
  ClassMirror? classMirror;

  @override
  void initState() {
    initializeReflectable();

    var type = {
          matrix.Client: ReflectableMatrixClient,
          matrix.Room: ReflectableMatrixRoom,
        }[widget.value.runtimeType] ??
        widget.value.runtimeType;

    if (reflector.canReflectType(type)) {
      classMirror = reflector.reflectType(type) as ClassMirror;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (classMirror == null) {
      return tiamat.Text.label(widget.value.toString());
    }

    var sorted = classMirror!.instanceMembers.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return ExpansionTile(
        title: tiamat.Text.label(
            "${FieldInspectorState.displayValue(widget.value)}"),
        children: [
          Column(
              children: sorted.map((e) {
            print("Building: ${e}");

            return FieldInspector(
              declaration: classMirror!.instanceMembers[e]!,
              instance: widget.value,
            );
          }).toList()),
        ]);
  }
}
