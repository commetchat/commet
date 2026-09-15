import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class AddWidgetDialog extends StatefulWidget {
  const AddWidgetDialog({
    super.key,
    required this.widgetUri,
    required this.room,
  });

  final AddWidgetURI widgetUri;
  final Room room;

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  bool addingWidget = false;

  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(widget.widgetUri.widgetUrl);
    return SizedBox(
      width: 500,
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              spacing: 8,
              children: [
                if (widget.widgetUri.widgetAvatarMxc != null)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Image(
                        fit: BoxFit.cover,
                        image: MatrixMxcImage(
                            Uri.parse(widget.widgetUri.widgetAvatarMxc!),
                            doThumbnail: false,
                            doFullres: true,
                            (widget.room.client as MatrixClient).matrixClient)),
                  ),
                tiamat.Text.label(
                    "Add the widget '${widget.widgetUri.widgetName ?? "Custom"}' to ${widget.room.displayName}?"),
              ],
            ),
          ),
          tiamat.Text.labelLow("Host: ${uri.scheme}://${uri.host}"),
          if (widget.widgetUri.previewMxc != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: SizedBox(
                  height: 300,
                  child: Image(
                      fit: BoxFit.cover,
                      image: MatrixMxcImage(
                          Uri.parse(widget.widgetUri.previewMxc!),
                          doThumbnail: false,
                          doFullres: true,
                          (widget.room.client as MatrixClient).matrixClient)),
                ),
              ),
            ),
          tiamat.Button(
            text: "Add Widget",
            isLoading: addingWidget,
            onTap: () async {
              var comp = widget.room.client.getComponent<WidgetComponent>();
              if (comp != null) {
                setState(() {
                  addingWidget = true;
                });

                await ErrorUtils.tryRun(context, () async {
                  await comp.addWidget(
                      url: Uri.parse(widget.widgetUri.widgetUrl),
                      room: widget.room,
                      iconImageUrl: widget.widgetUri.widgetAvatarMxc != null
                          ? Uri.tryParse(widget.widgetUri.widgetAvatarMxc!)
                          : null,
                      widgetName: widget.widgetUri.widgetName ?? "Custom",
                      widgetType: widget.widgetUri.widgetType);
                });

                Navigator.of(context).pop();
              }
            },
          ),
          tiamat.Button.secondary(
            text: "Cancel",
            onTap: () => Navigator.of(context).pop(),
          ),
          tiamat.Text.error(
              "Widgets are hosted on external websites, and the code can be changed without notice. Do not use the widget if you do not trust the host.")
        ],
      ),
    );
  }
}
