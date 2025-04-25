import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/utils/animation/ring_shaker.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class SidebarCallIconView extends StatelessWidget {
  const SidebarCallIconView(this.state,
      {this.avatar,
      this.roomName,
      this.color,
      this.onTap,
      this.audioLevel = 0,
      required this.width,
      super.key});
  final double width;
  final Color? color;
  final String? roomName;
  final ImageProvider? avatar;
  final VoipState state;
  final double audioLevel;
  final Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SpaceSelector.padding,
      child: AspectRatio(
        aspectRatio: 1,
        child: pickAnimation(
          child: ImageButton(
            size: width,
            placeholderColor: color,
            placeholderText: roomName,
            onTap: onTap,
            image: avatar,
            // TODO: REIMPLEMENT BORDER
            // boxBorder: Border.all(
            // color: getBorderColor(context),
            // width: 3,
            // strokeAlign: BorderSide.strokeAlignCenter),
          ),
        ),
      ),
    );
  }

  Color getBorderColor(BuildContext context) {
    if (state == VoipState.connected) {
      return Color.lerp(Theme.of(context).primaryColor,
          Theme.of(context).colorScheme.primary, audioLevel)!;
    }

    return Theme.of(context).primaryColor;
  }

  Widget pickAnimation({required Widget child}) {
    if (state == VoipState.incoming) {
      return RingShakerAnimation(child: child);
    }

    return child;
  }
}
