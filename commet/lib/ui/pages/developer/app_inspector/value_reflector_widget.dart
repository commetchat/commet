import 'package:commet/main.reflectable.dart';
import 'package:commet/ui/pages/developer/app_inspector/field_inspector.dart';
import 'package:commet/ui/pages/developer/app_inspector/reflectable_matrix_client.dart';
import 'package:flutter/material.dart';
import 'package:reflectable/reflectable.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:matrix/matrix.dart' as matrix;

// ignore: implementation_imports
import 'package:matrix/src/utils/space_child.dart';

class Reflector extends Reflectable {
  const Reflector()
      : super(typingCapability, invokingCapability,
            libraryDependenciesCapability);
}

const reflector = Reflector();

class ValueReflectorWidget extends StatefulWidget {
  const ValueReflectorWidget({required this.value, super.key, this.index = 0});
  final dynamic value;
  final int index;

  @override
  State<ValueReflectorWidget> createState() => _ValueReflectorWidgetState();
}

class _ValueReflectorWidgetState extends State<ValueReflectorWidget> {
  ClassMirror? classMirror;
  late List<String> keys;
  @override
  void initState() {
    initializeReflectable();

    var type = {
          matrix.Client: ReflectableMatrixClient,
          matrix.Room: ReflectableMatrixRoom,
          matrix.Event: ReflectableMatrixEvent,
          SpaceChild: ReflectableMatrixSpaceChild,
          SpaceParent: ReflectableMatrixSpaceParent,
          matrix.BasicEvent: ReflectableMatrixBasicEvent
        }[widget.value.runtimeType] ??
        widget.value.runtimeType;

    if (reflector.canReflectType(type)) {
      classMirror = reflector.reflectType(type) as ClassMirror;
      keys = classMirror!.instanceMembers.keys.toList()
        ..sort((a, b) => a.compareTo(b))
        ..removeWhere((e) =>
            classMirror!.instanceMembers[e]!.isRegularMethod ||
            classMirror!.instanceMembers[e]!.isSetter);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (classMirror == null) {
      return tiamat.Text.labelLow(widget.value.toString());
    }

    final color = (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black)
        .withAlpha(7);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: ExpansionTile(
          backgroundColor: color,
          title:
              tiamat.Text.label(FieldInspectorState.displayValue(widget.value)),
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: keys.mapIndexed((e, i) {
                  if ([
                    "accessToken",
                    "bearerToken",
                    "fingerprintKey",
                    "identityKey"
                  ].contains(e)) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                      child: tiamat.Text.error("$e (Redacted)"),
                    );
                  }

                  return FieldInspector(
                    declaration: classMirror!.instanceMembers[e]!,
                    instance: widget.value,
                  );
                }).toList()),
          ]),
    );
  }
}
