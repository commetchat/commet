import 'dart:async';

import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_in_app_web_view_page.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_inappwebview_runner.dart';
import 'package:commet/config/layout_config.dart';

import 'package:commet/main.dart';
import 'package:commet/ui/atoms/floating_tile.dart';
import 'package:commet/ui/molecules/show_on_hover.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class InAppWebViewWidgetOverlay extends StatefulWidget {
  const InAppWebViewWidgetOverlay({
    super.key,
    required this.removeStream,
    required this.keepAlive,
    required this.runner,
  });

  final StreamController<dynamic> removeStream;
  final InAppWebViewKeepAlive keepAlive;
  final MatrixUserWidgetInAppWebviewRunner runner;

  @override
  State<InAppWebViewWidgetOverlay> createState() =>
      _InAppWebViewWidgetOverlayState();
}

class _InAppWebViewWidgetOverlayState extends State<InAppWebViewWidgetOverlay> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.runner.controller.platform.resumeTimers();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 300;

    if (Layout.mobile) {
      width = 350;
    }

    var height = width * (9 / 16);

    return FloatingTile(
        child: SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(10),
        child: Container(
            child: Stack(
          children: [
            MatrixWidgetInappwebviewRunnerWidget(
              keepAlive: widget.keepAlive,
              info: widget.runner.info,
            ),
            ShowOnHover(
                background: Container(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                child: Container(
                  color: ColorScheme.of(context)
                      .surfaceContainerLow
                      .withAlpha(150),
                  child: Stack(
                    children: [
                      Align(
                        alignment: AlignmentGeometry.topRight,
                        child: SizedBox(
                            width: 50,
                            height: 50,
                            child: tiamat.IconButton(
                              icon: Icons.close,
                              size: 25,
                              onPressed: onClose,
                              iconColor: ColorScheme.of(context).onSurface,
                            )),
                      ),
                      Center(
                          child: SizedBox(
                              width: 50,
                              height: 50,
                              child: tiamat.IconButton(
                                icon: Icons.fullscreen,
                                size: 25,
                                onPressed: onFullscreen,
                                iconColor: ColorScheme.of(context).onSurface,
                              ))),
                    ],
                  ),
                )),
          ],
        )),
      ),
    ));
  }

  onFullscreen() {
    var keepAlive = widget.keepAlive;
    var info = widget.runner.info;
    var runner = widget.runner;

    widget.removeStream.add(null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationUtils.navigateTo(
          navigator.currentContext!,
          MatrixWidgetInappwebviewPage(
            keepAlive: keepAlive,
            info: info,
            runner: runner,
          ));
    });
  }

  onClose() {
    widget.removeStream.add(null);
    widget.runner.dispose();
  }
}
