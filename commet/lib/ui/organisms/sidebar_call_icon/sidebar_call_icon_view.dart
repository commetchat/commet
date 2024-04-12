import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/utils/animation/ring_shaker.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

class SidebarCallIconView extends StatelessWidget {
  const SidebarCallIconView(this.state,
      {this.avatar,
      this.callerName,
      this.color,
      required this.width,
      super.key});
  final double width;
  final Color? color;
  final String? callerName;
  final ImageProvider? avatar;
  final VoipState state;

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
            placeholderText: callerName,
            image: avatar,
            boxBorder: Border.all(color: getBorderColor(context), width: 4),
          ),
        ),
      ),
    );
  }

  Color getBorderColor(BuildContext context) {
    if (state == VoipState.connected) {
      return Theme.of(context).colorScheme.primary;
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
