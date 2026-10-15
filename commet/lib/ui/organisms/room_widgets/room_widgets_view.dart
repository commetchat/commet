import 'dart:async';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/links/link_utils.dart';
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

  StreamSubscription? sub;

  @override
  void initState() {
    var client = widget.room.client;

    var widgetComponent = client.getComponent<WidgetComponent>();

    widgets = widgetComponent!.getWidgets(widget.room);

    sub = widgetComponent.onWidgetsChanged.listen(onWidgetsChanged);

    additionalHostTypes = widgetComponent
        .supportedHostTypes()
        .where((i) => i != widgetComponent.defaultHostType)
        .toList();

    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void onWidgetsChanged(void event) {
    setState(() {
      var client = widget.room.client;
      var widgetComponent = client.getComponent<WidgetComponent>();
      widgets = widgetComponent!.getWidgets(widget.room);
    });
  }

  String hostTypeToLabel(WidgetHostType type) {
    return switch (type) {
      WidgetHostType.embedded => "Open embedded",
      WidgetHostType.childProcess => "Open in new window",
      WidgetHostType.remoteHttpClient => "Open on another device",
      WidgetHostType.externalBrowser => "Open in browser",
      WidgetHostType.androidActivity => "Open in new activity",
    };
  }

  IconData hostTypeToIcon(WidgetHostType type) {
    return switch (type) {
      WidgetHostType.embedded => Icons.widgets_rounded,
      WidgetHostType.childProcess => Icons.open_in_new,
      WidgetHostType.remoteHttpClient => Icons.qr_code_rounded,
      WidgetHostType.externalBrowser => Icons.open_in_browser,
      WidgetHostType.androidActivity => Icons.widgets_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Tile.low(
      child: ScaledSafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            if (widgets.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.labelLow(
                    "No widgets have been added to this room"),
              ),
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
                            ),
                            tiamat.ContextMenuItem(
                              text: "Remove Widget",
                              icon: Icons.delete_forever,
                              color: ColorScheme.of(context).error,
                              onPressed: () async {
                                if (await AdaptiveDialog.confirmation(context,
                                        prompt:
                                            "Are you sure you want to remove the widget '${data.name}' from '${widget.room.displayName}'?") ==
                                    true) {
                                  var comp = widget.room.client
                                      .getComponent<WidgetComponent>();
                                  comp?.removeWidget(
                                      widget: data, room: widget.room);
                                }
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
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: SizedBox(
                  height: 50,
                  child: tiamat.TextButton(
                    "Browse Widgets",
                    icon: Icons.open_in_browser,
                    onTap: () {
                      LinkUtils.open(
                        Uri.parse("https://commet.chat/widgets"),
                        context: context,
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
