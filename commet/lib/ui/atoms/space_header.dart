import 'package:commet/client/components/space_color_scheme/space_color_scheme_component.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';

class SpaceHeader extends StatelessWidget {
  const SpaceHeader(this.space,
      {this.onTap, this.backgroundColor = Colors.transparent, super.key});
  final Space space;
  final Color backgroundColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    var comp = space.getComponent<SpaceColorSchemeComponent>();
    if (comp != null) {
      colorScheme = comp.scheme;
    }

    EdgeInsets padding = MediaQuery.of(context).scale().viewPadding;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(
            height: 100 + MediaQuery.of(context).padding.top),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (space.avatar != null)
              Image(
                image: space.avatar!,
                fit: BoxFit.cover,
                alignment: padding.top > 0
                    ? AlignmentGeometry.xy(0, -0.25)
                    : Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            Material(
              color: space.avatar != null
                  ? Colors.transparent
                  : colorScheme.primary,
              child: InkWell(
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: space.avatar != null
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
                      child: Text(space.displayName,
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                  color: colorScheme.onPrimary,
                                  shadows: space.avatar != null
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
