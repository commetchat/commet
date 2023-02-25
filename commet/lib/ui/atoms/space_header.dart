import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/style/theme_extensions.dart';

class SpaceHeader extends StatelessWidget {
  const SpaceHeader(this.space, {super.key});
  final Space space;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2, width: 1.5)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)],
            color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(space.displayName, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
