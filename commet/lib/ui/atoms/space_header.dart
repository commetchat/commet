import 'dart:ui';

import 'package:commet/ui/atoms/blurred_image_background.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';
import '../../config/app_config.dart';

class SpaceHeader extends StatelessWidget {
  const SpaceHeader(this.space, {this.onTap, this.backgroundColor = Colors.transparent, super.key});
  final Space space;
  final Color backgroundColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    if (space.avatar != null) {
      return BlurredImageBackground(space.avatar!, backgroundColor: backgroundColor, child: layout(context));
    }
    return layout(context);
  }

  Widget layout(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap?.call();
        },
        child: Padding(
          padding: EdgeInsets.all(s(10.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(space.displayName, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
