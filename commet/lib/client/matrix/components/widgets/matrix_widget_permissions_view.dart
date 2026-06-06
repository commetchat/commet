import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_permission_groups.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixWidgetPermissionsView extends StatefulWidget {
  const MatrixWidgetPermissionsView(
      {required this.runner,
      required this.groupedPermissions,
      required this.ungrouped,
      super.key});

  final List<MatrixWidgetPermissionGroup> groupedPermissions;
  final List<MatrixWidgetCapabilityString> ungrouped;
  final WidgetRunner runner;

  @override
  State<MatrixWidgetPermissionsView> createState() =>
      _MatrixWidgetPermissionsViewState();
}

class _MatrixWidgetPermissionsViewState
    extends State<MatrixWidgetPermissionsView> {
  Map<String, bool> enabledPermissions = {};

  @override
  void initState() {
    for (var group in widget.groupedPermissions) {
      for (var entry in group.permissions) {
        enabledPermissions[entry.raw] = group.defaultValue;
      }
    }

    for (var entry in widget.ungrouped) {
      enabledPermissions[entry.raw] = true;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 700, maxWidth: 700),
      child: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.label(
                    "'${widget.runner.info.name}' would like permission to do the following actions on your behalf:"),
              ),
              buildGroups(),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.ungrouped.length,
                itemBuilder: (context, index) {
                  var item = widget.ungrouped[index];
                  return buildItem(item);
                },
              ),
              SizedBox(
                height: 10,
              ),
              if (enabledPermissions.values.any((i) => i == false))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tiamat.Text.labelLow(
                      "Some permissions will not be granted, the widget may not function as intended"),
                ),
              tiamat.Button(
                text: "Submit",
                onTap: () {
                  Navigator.of(context).pop(enabledPermissions.entries
                      .where((i) => i.value == true)
                      .map((i) => i.key)
                      .toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGroups() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(0),
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.groupedPermissions.length,
      itemBuilder: (context, index) {
        var item = widget.groupedPermissions[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
          child: buildGroup(item),
        );
      },
    );
  }

  Widget buildGroup(MatrixWidgetPermissionGroup group) {
    bool dangerous = group.severity == WidgetPermissionSeverity.critical;
    var bg = dangerous
        ? ColorScheme.of(context).errorContainer.withAlpha(165)
        : Theme.of(context).colorScheme.surface;

    return ExpansionTile(
        title: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: group.permissions
                        .any((i) => enabledPermissions[i.raw] == true),
                    onChanged: (value) {
                      setState(() {
                        for (var entry in group.permissions) {
                          enabledPermissions[entry.raw] = value == true;
                        }
                      });
                    },
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                              child: Icon(
                                group.icon,
                                size: 20,
                              ),
                            ),
                            tiamat.Text.labelEmphasised(group.name),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                              child: tiamat.Text.labelLow(
                                  "(${group.permissions.length})"),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                          child: tiamat.Text.labelLow(group.description),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: buildSeverityIcon(group),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        collapsedBackgroundColor: bg,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Column(
              children: group.permissions.map((i) => buildItem(i)).toList(),
            ),
          )
        ]);
  }

  Widget buildSeverityIcon(MatrixWidgetPermissionGroup group) {
    if (group.severity == WidgetPermissionSeverity.low) return Container();

    Color color = severityColor(group);

    var icon = switch (group.severity) {
      WidgetPermissionSeverity.low => Icons.info_outline,
      WidgetPermissionSeverity.mild => Icons.warning_amber_rounded,
      WidgetPermissionSeverity.high => Icons.warning_rounded,
      WidgetPermissionSeverity.critical => Icons.warning_rounded,
    };

    return Icon(
      icon,
      color: color,
    );
  }

  Color severityColor(MatrixWidgetPermissionGroup group) {
    var color = switch (group.severity) {
      WidgetPermissionSeverity.low => ColorScheme.of(context).onSurface,
      WidgetPermissionSeverity.mild => Colors.amberAccent,
      WidgetPermissionSeverity.high => ColorScheme.of(context).error,
      WidgetPermissionSeverity.critical => ColorScheme.of(context).error,
    };

    return color;
  }

  Widget buildItem(MatrixWidgetCapabilityString capability) {
    return InkWell(
      onTap: () {
        setState(() {
          enabledPermissions[capability.raw] =
              !enabledPermissions[capability.raw]!;
        });
      },
      child: Row(
        children: [
          Checkbox(
            value: enabledPermissions[capability.raw],
            onChanged: (value) {
              setState(() {
                enabledPermissions[capability.raw] = value == true;
              });
            },
          ),
          tiamat.Text.labelLow(capability.raw),
        ],
      ),
    );
  }
}
