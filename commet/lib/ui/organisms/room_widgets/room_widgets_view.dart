import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/room.dart';
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

  @override
  void initState() {
    var client = widget.room.client;
    var widgetComponent = client.getComponent<WidgetComponent>();
    widgets = widgetComponent!.getWidgets(widget.room);

    super.initState();
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
                      child: tiamat.TextButton(
                        data.name,
                        icon: Icons.widgets,
                        onTap: () async {
                          var client = widget.room.client;
                          var widgetComponent =
                              client.getComponent<WidgetComponent>();

                          var supportedTypes =
                              widgetComponent!.supportedHostTypes();

                          var picked = await AdaptiveDialog.pickOne(
                            context,
                            items: supportedTypes,
                            itemBuilder: (context, item, callback) {
                              return tiamat.TextButton(item.toString(), onTap: callback,);
                            },
                          );

                          if (picked != null) {
                            widgetComponent.openWidget(
                                data, widget.room, context, picked);
                          }
                        },
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
