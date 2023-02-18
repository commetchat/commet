import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class SpaceIcon extends StatefulWidget {
  SpaceIcon(this.space, {super.key, this.width = 44, this.onTap});
  final Space space;
  double width;
  void Function()? onTap;

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
                child: AnimatedContainer(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
