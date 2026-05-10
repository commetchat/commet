import 'dart:async';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_in_app_web_view_overlay.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_inappwebview_runner.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixWidgetInAppWebviewCreationParms {
  final String url;
  final String widgetId;
  final String userScript;
  final MatrixRoom room;
  final MatrixWidgetComponent component;

  MatrixWidgetInAppWebviewCreationParms({
    required this.url,
    required this.widgetId,
    required this.userScript,
    required this.room,
    required this.component,
  });
}

class MatrixWidgetInappwebviewPage extends StatefulWidget {
  const MatrixWidgetInappwebviewPage(
      {this.creationParms,
      required this.keepAlive,
      required this.info,
      this.runner,
      super.key});
  final MatrixWidgetInAppWebviewCreationParms? creationParms;
  final UserWidgetInfo info;
  final InAppWebViewKeepAlive keepAlive;
  final MatrixUserWidgetInAppWebviewRunner? runner;

  @override
  State<MatrixWidgetInappwebviewPage> createState() =>
      _MatrixWidgetInappwebviewPageState();
}

class _MatrixWidgetInappwebviewPageState
    extends State<MatrixWidgetInappwebviewPage> {
  bool showing = true;

  MatrixUserWidgetInAppWebviewRunner? runner;

  @override
  void initState() {
    runner = widget.runner;
    super.initState();
  }

  void onBack() {
    moveToOverlay();
    Navigator.of(context).pop();
  }

  void moveToOverlay() {
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    setState(() {
      showing = false;
    });

    runner!.controller.platform.pauseTimers();

    var removeStream = StreamController();

    overlayEntry = OverlayEntry(
      builder: (context) {
        return InAppWebViewWidgetOverlay(
          removeStream: removeStream,
          keepAlive: widget.keepAlive,
          runner: runner!,
        );
      },
    );

    removeStream.stream.listen((_) {
      overlayEntry.remove();
    });

    // Inserting the OverlayEntry into the Overlay
    overlayState.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = 40.0;

    return Material(
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (showing) {
            moveToOverlay();
          }
        },
        child: tiamat.Tile.lowest(
          child: ScaledSafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                    height: buttonSize,
                    child: HeaderView(
                      text: widget.info.name,
                      showBurger: false,
                      menu: Row(
                        spacing: 8,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: buttonSize,
                              child: tiamat.IconButton(
                                icon: Icons.minimize,
                                onPressed: onBack,
                              )),
                          SizedBox(
                              width: buttonSize,
                              child: tiamat.IconButton(
                                icon: Icons.close,
                                onPressed: () {
                                  showing = false;
                                  runner?.dispose();
                                  Navigator.of(context).pop();
                                },
                              )),
                        ],
                      ),
                    )),
                if (showing)
                  Expanded(
                      child: Placeholder(
                    child: MatrixWidgetInappwebviewRunnerWidget(
                      keepAlive: widget.keepAlive,
                      url: widget.creationParms?.url,
                      info: widget.info,
                      widgetId: widget.creationParms?.widgetId,
                      userScript: widget.creationParms?.userScript,
                      room: widget.creationParms?.room,
                      component: widget.creationParms?.component,
                      initialize: widget.creationParms != null,
                      onRunnerCreated: (p0) {
                        Log.i("Created widget runner!");

                        setState(() {
                          runner = p0;
                        });
                      },
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
