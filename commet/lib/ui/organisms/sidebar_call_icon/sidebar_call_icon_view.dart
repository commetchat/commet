import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/utils/animation/ring_shaker.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class SidebarCallIconView extends StatelessWidget {
  const SidebarCallIconView(
      {this.avatar, this.color, required this.width, super.key});
  final double width;
  final Color? color;
  final ImageProvider? avatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SpaceSelector.padding,
      child: AspectRatio(
        aspectRatio: 1,
        child: RingShakerAnimation(
          child: ImageButton(
            size: width,
            placeholderColor: color,
            placeholderText: "A",
            image: avatar,
          ),
        ),
      ),
    );
  }
}
