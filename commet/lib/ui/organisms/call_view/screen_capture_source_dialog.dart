import 'package:commet/ui/organisms/call_view/screen_capture_source_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenCaptureDialogResult {
  final DesktopCapturerSource source;
  final bool doNotShareAudio;

  const ScreenCaptureDialogResult({
    required this.source,
    this.doNotShareAudio = false,
  });

  bool get captureAudio => !doNotShareAudio;
}

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
  bool doNotShareAudio = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      height: 700,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: MasonryGridView.count(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                crossAxisCount: 2,
                shrinkWrap: true,
                itemCount: widget.sources.length,
                itemBuilder: (context, index) {
                  return ScreenCaptureSourceWidget(
                    widget.sources[index],
                    widget.onThumbnailChanged,
                    onTap: () => Navigator.of(context).pop(
                      ScreenCaptureDialogResult(
                        source: widget.sources[index],
                        doNotShareAudio: doNotShareAudio,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                doNotShareAudio = !doNotShareAudio;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: doNotShareAudio,
                    onChanged: (val) {
                      setState(() {
                        doNotShareAudio = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Não compartilhar áudio do sistema'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
