import 'dart:async';
import 'package:commet/client/components/space_banner/space_banner_component.dart';
import 'package:commet/client/components/space_color_scheme/space_color_scheme_component.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';

class SpaceHeader extends StatefulWidget {
  const SpaceHeader(this.space,
      {this.onTap, this.backgroundColor = Colors.transparent, super.key});
  final Space space;
  final Color backgroundColor;
  final void Function()? onTap;

  @override
  State<SpaceHeader> createState() => _SpaceHeaderState();
}

class _SpaceHeaderState extends State<SpaceHeader> {
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.space.onUpdate.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    var comp = widget.space.getComponent<SpaceColorSchemeComponent>();
    if (comp != null) {
      colorScheme = comp.scheme;
    }

    EdgeInsets padding = MediaQuery.of(context).scale().viewPadding;

    var banner = widget.space.getComponent<SpaceBannerComponent>();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(
            height: 100 + MediaQuery.of(context).padding.top),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner?.banner != null || widget.space.avatar != null)
              Image(
                image: banner?.banner ?? widget.space.avatar!,
                fit: BoxFit.cover,
                alignment: padding.top > 0
                    ? AlignmentGeometry.xy(0, -0.25)
                    : Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            Material(
              color: widget.space.avatar != null
                  ? Colors.transparent
                  : colorScheme.primary,
              child: InkWell(
                onTap: widget.onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: widget.space.avatar != null
                          ? LinearGradient(
                              begin: AlignmentGeometry.bottomCenter,
                              end: AlignmentGeometry.topCenter,
                              colors: [colorScheme.primary, Colors.transparent],
                            )
                          : null),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
                      child: Text(widget.space.displayName,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: colorScheme.onPrimary,
                                  shadows: widget.space.avatar != null
                                      ? [
                                          const BoxShadow(
                                              blurRadius: 2,
                                              spreadRadius: 10,
                                              color: Colors.black,
                                              offset: Offset(2, 2))
                                        ]
                                      : null)),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
