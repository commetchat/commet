import 'dart:async';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/subprocess/matrix_widget_desktop_runner.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/widget_debug_view.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class WidgetSessionsPanel extends StatefulWidget {
  const WidgetSessionsPanel({this.height = 50, super.key});
  final double height;
  @override
  State<WidgetSessionsPanel> createState() => _WidgetSessionsPanelState();
}

class _WidgetSessionsPanelState extends State<WidgetSessionsPanel> {
  StreamSubscription? sub;

  @override
  void initState() {
    sub = WidgetComponent.currentSessions.onListUpdated.listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (WidgetComponent.currentSessions.isEmpty) return Container();

    Iterable<WidgetRunner> widgets = WidgetComponent.currentSessions;

    if (preferences.widgetDeveloperMode.value == false) {
      widgets = WidgetComponent.currentSessions.where((i) =>
          (i is MatrixUserWidgetSubprocessRunner && i.hidden) ? false : true);
    }

    var first = widgets.firstOrNull;

    if (first == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        for (var entry in widgets) buildEntry(context, entry),
      ],
    );
  }

  Widget buildEntry(
      BuildContext context, WidgetRunner<dynamic, dynamic> entry) {
    return SizedBox(
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceTint.withAlpha(10),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                    height: widget.height,
                    width: widget.height,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: entry.info.icon.build(context),
                    )),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    tiamat.Text(entry.info.name),
                  ],
                ),
              ],
            ),
            Row(
              spacing: 2,
              children: [
                if (preferences.widgetDeveloperMode.value)
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: tiamat.IconButton(
                      icon: Icons.code,
                      onPressed: () {
                        AdaptiveDialog.show(
                          context,
                          builder: (context) {
                            return SizedBox(
                                width: 700,
                                height: 700,
                                child: WidgetDebugView(
                                    entry as MatrixWidgetRunner));
                          },
                        );
                      },
                    ),
                  ),
                AspectRatio(
                  aspectRatio: 1.0,
                  child: tiamat.IconButton(
                    icon: Icons.close,
                    iconColor: ColorScheme.of(context).error,
                    onPressed: () async {
                      if ((await AdaptiveDialog.confirmation(context)) ==
                          true) {
                        entry.dispose();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
