import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/atoms/popup_dialog.dart';

class Lightbox extends StatefulWidget {
  const Lightbox({required this.image, super.key});
  final ImageProvider image;
  @override
  State<Lightbox> createState() => _LightboxState();

  static void show(BuildContext context, {required ImageProvider image}) {
    showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "LIGHTBOX",
        barrierColor: PopupDialog.barrierColor,
        pageBuilder: (context, _, __) {
          return Lightbox(
            image: image,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }
}

class _LightboxState extends State<Lightbox> {
  @override
  void initState() {
    super.initState();
  }

  // void getImageInfo() async {
  //   widget.image.resolve(new ImageConfiguration()).addListener(ImageStreamListener((image, synchronousCall) {
  //     image.image
  //   }));
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50.0),
      child: Container(
        color: Colors.red,
        child: Image(
          image: widget.image,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
