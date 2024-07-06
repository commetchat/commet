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
                filterQuality: FilterQuality.medium,
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
                    child: Text(space.displayName,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: space.avatar != null ? Colors.white : null,
                            fontWeight: FontWeight.w500,
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
            )
          ],
        ),
      ),
    );
  }
}
