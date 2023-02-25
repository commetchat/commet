import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

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
  BorderRadiusGeometry _borderRadius = BorderRadius.circular(20);

  @override
  void initState() {
    widget.space.onUpdate.stream.listen((event) {
      print("Space State Updated");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GestureDetector(
              onTap: () => {widget.onTap?.call()},
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (event) {
                  setState(() {
                    _borderRadius = BorderRadius.circular(8);
                  });
                },
                onExit: (event) {
                  setState(() {
                    _borderRadius = BorderRadius.circular(20);
                  });
                },
                child: JustTheTooltip(
                  preferredDirection: AxisDirection.right,
                  offset: 40,
                  tailLength: 5,
                  tailBaseWidth: 5,
                  //shadow: BoxShadow(blurRadius: 4, color: Colors.black, spreadRadius: 1),
                  backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLowest,
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.space.displayName),
                  ),
                  child: Stack(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                          borderRadius: _borderRadius,
                          image: widget.space.avatar != null
                              ? DecorationImage(image: widget.space.avatar!, fit: BoxFit.fitHeight)
                              : const DecorationImage(
                                  image: AssetImage("assets/images/placeholder/generic/checker_red.png"),
                                  fit: BoxFit.fitHeight)),
                    ),
                    if (widget.showUser && widget.space.client.user!.avatar != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                              image: DecorationImage(image: widget.space.client.user!.avatar!, fit: BoxFit.fitHeight),
                              //border: Border.all(color: Colors.white, width: 1)),
                            ),
                          ),
                        ),
                      )
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
