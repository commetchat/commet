import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../../config/app_config.dart';

class SpaceIcon extends StatefulWidget {
  const SpaceIcon(this.space, {super.key, this.width = 44, this.onTap, this.showUser = false});
  final Space space;
  final double width;
  final void Function()? onTap;
  final bool showUser;

  @override
  State<SpaceIcon> createState() => _SpaceIconState();
}

class _SpaceIconState extends State<SpaceIcon> {
  @override
  void initState() {
    widget.space.onUpdate.stream.listen((event) {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ImageButton(
        //tooltip: widget.space.displayName,
        image: widget.space.avatar,
        onTap: widget.onTap,
        size: widget.width,
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
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
            image: DecorationImage(image: widget.space.client.user!.avatar!, fit: BoxFit.fitHeight),
            //border: Border.all(color: Colors.white, width: 1)),
          ),
        ),
      ),
    );
  }
}
