import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomWidgetsView extends StatefulWidget {
  const RoomWidgetsView(this.room, {super.key});
  final Room room;

  @override
  State<RoomWidgetsView> createState() => _RoomWidgetsViewState();
}

class _RoomWidgetsViewState extends State<RoomWidgetsView> {
  late List<UserWidgetInfo> widgets;
  late List<WidgetHostType> additionalHostTypes;

  @override
  void initState() {
    var client = widget.room.client;
    var widgetComponent = client.getComponent<WidgetComponent>();
    widgets = widgetComponent!.getWidgets(widget.room);

    additionalHostTypes = widgetComponent
        .supportedHostTypes()
        .where((i) => i != widgetComponent.defaultHostType)
        .toList();

    super.initState();
  }

  String hostTypeToLabel(WidgetHostType type) {
    return switch (type) {
      WidgetHostType.embedded => "Open embedded",
      WidgetHostType.childProcess => "Open in new window",
      WidgetHostType.remoteHttpClient => "Open on another device",
      WidgetHostType.externalBrowser => "Open in browser",
    };
  }

  IconData hostTypeToIcon(WidgetHostType type) {
    return switch (type) {
      WidgetHostType.embedded => Icons.widgets_rounded,
      WidgetHostType.childProcess => Icons.open_in_new,
      WidgetHostType.remoteHttpClient => Icons.qr_code_rounded,
      WidgetHostType.externalBrowser => Icons.open_in_browser,
    };
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Tile.low(
      child: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(0),
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                var data = widgets[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 40,
                      child: AdaptiveContextMenu(
                        items: [
                          for (var i in additionalHostTypes)
                            tiamat.ContextMenuItem(
                              text: hostTypeToLabel(i),
                              icon: hostTypeToIcon(i),
                              onPressed: () {
                                WidgetComponent.runWidget(
                                    widget.room, context, data,
                                    type: i);
                              },
                            ),
                          tiamat.ContextMenuItem(
                            text: "Clear Permissions",
                            icon: Icons.delete,
                            color: ColorScheme.of(context).error,
                            onPressed: () {
                              preferences.clearWidgetSettings(
                                  widget.room.client.identifier,
                                  data.namespace);
                            },
                          )
                        ],
                        child: tiamat.TextButton(
                          data.name,
                          icon: data.icon.icon,
                          avatar: data.icon.image,
                          onTap: () async {
                            WidgetComponent.runWidget(
                                widget.room, context, data);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
