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
    if (space.avatar != null) {
      return Material(
          child: Ink.image(
        image: space.avatar!,
        fit: BoxFit.cover,
        child: layout(context),
      ));
    }
    return Material(
        color: Theme.of(context).colorScheme.surface, child: layout(context));
  }

  Widget layout(BuildContext context) {
    return InkWell(
      onTap: () => onTap?.call(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(space.displayName,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: space.avatar != null ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                    shadows: space.avatar != null
                        ? [
                            BoxShadow(
                                color: Theme.of(context).shadowColor,
                                offset: const Offset(2, 2))
                          ]
                        : null)),
          ],
        ),
      ),
    );
  }
}
