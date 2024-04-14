// import 'package:commet/ui/organisms/call_view/screen_capture_source_widget.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class ScreenCaptureSourceDialog extends StatelessWidget {
//   const ScreenCaptureSourceDialog(this.sources, {super.key});
//   final List<DesktopCapturerSource> sources;
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 700,
//       height: 700,
//       child: SingleChildScrollView(
//         child: MasonryGridView.count(
//           mainAxisSpacing: 4,
//           crossAxisSpacing: 4,
//           physics: const NeverScrollableScrollPhysics(),
//           addAutomaticKeepAlives: false,
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           itemCount: sources.length,
//           itemBuilder: (context, index) {
//             return ScreenCaptureSourceWidget(
//               sources[index],
//               onTap: () => Navigator.of(context).pop(sources[index]),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
