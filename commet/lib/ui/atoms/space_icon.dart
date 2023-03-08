import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:commet/ui/atoms/side_panel_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';

class SpaceIcon extends StatefulWidget {
  SpaceIcon(this.space, {super.key, this.width = 44, this.onTap, this.showUser = false});
  final Space space;
  double width;
  void Function()? onTap;
  bool showUser;

  @override
  State<SpaceIcon> createState() => _SpaceIconState();
}

class _SpaceIconState extends State<SpaceIcon> {
  @override
  void initState() {
    widget.space.onUpdate.stream.listen((event) {
      print("Space State Updated");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SidePanelButton(
        tooltip: widget.space.displayName,
        image: widget.space.avatar,
        onTap: widget.onTap,
      ),
      if (widget.showUser && widget.space.client.user!.avatar != null) avatarOverlay()
    ]);
  }

  Positioned avatarOverlay() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: SizedBox(
        width: s(20),
        height: s(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(20)),
            boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
            image: DecorationImage(image: widget.space.client.user!.avatar!, fit: BoxFit.fitHeight),
            //border: Border.all(color: Colors.white, width: 1)),
          ),
        ),
      ),
    );
  }
}
