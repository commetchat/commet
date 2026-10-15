import 'package:commet/ui/organisms/call_view/screen_capture_source_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class ScreenCaptureSourceDialog extends StatefulWidget {
  const ScreenCaptureSourceDialog(this.sources, this.onThumbnailChanged,
      {super.key});
  final List<DesktopCapturerSource> sources;
  final Stream<DesktopCapturerSource> onThumbnailChanged;

  @override
  State<ScreenCaptureSourceDialog> createState() =>
      _ScreenCaptureSourceDialogState();
}

class _ScreenCaptureSourceDialogState extends State<ScreenCaptureSourceDialog> {
  late List<DesktopCapturerSource> screenSources;
  late List<DesktopCapturerSource> windowSources;

  @override
  void initState() {
    this.screenSources =
        widget.sources.where((i) => i.type == SourceType.Screen).toList();
    this.windowSources =
        widget.sources.where((i) => i.type == SourceType.Window).toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      height: 700,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (windowSources.isNotEmpty) ...[
              tiamat.Text.largeTitle("Windows:"),
              MasonryGridView.count(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                crossAxisCount: 2,
                shrinkWrap: true,
                itemCount: windowSources.length,
                itemBuilder: (context, index) {
                  return ScreenCaptureSourceWidget(
                    windowSources[index],
                    widget.onThumbnailChanged,
                    onTap: () =>
                        Navigator.of(context).pop(windowSources[index]),
                  );
                },
              ),
              SizedBox(
                height: 32,
              )
            ],
            if (screenSources.isNotEmpty) ...[
              tiamat.Text.largeTitle("Screens:"),
              MasonryGridView.count(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                crossAxisCount: 2,
                shrinkWrap: true,
                itemCount: screenSources.length,
                itemBuilder: (context, index) {
                  return ScreenCaptureSourceWidget(
                    screenSources[index],
                    widget.onThumbnailChanged,
                    onTap: () =>
                        Navigator.of(context).pop(screenSources[index]),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
