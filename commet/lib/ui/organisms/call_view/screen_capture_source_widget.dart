// import 'package:flutter/material.dart';

// import 'package:tiamat/tiamat.dart' as tiamat;

// class ScreenCaptureSourceWidget extends StatefulWidget {
//   const ScreenCaptureSourceWidget(this.source, {this.onTap, super.key});
//   // final DesktopCapturerSource source;

//   final Function()? onTap;

//   @override
//   State<ScreenCaptureSourceWidget> createState() =>
//       _ScreenCaptureSourceWidgetState();
// }

// class _ScreenCaptureSourceWidgetState extends State<ScreenCaptureSourceWidget> {
//   @override
//   void initState() {
//     super.initState();

//     widget.source.onThumbnailChanged.stream.listen((event) {
//       setState(() {});
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(8),
//       child: tiamat.Tile.low2(
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: widget.onTap,
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
//                   child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: buildImage()),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: tiamat.Text.labelLow(widget.source.name),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildImage() {
//     if (widget.source.thumbnail != null) {
//       return Image.memory(widget.source.thumbnail!);
//     } else {
//       return const SizedBox(
//         width: 200,
//         height: 200,
//         child: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//   }
// }
