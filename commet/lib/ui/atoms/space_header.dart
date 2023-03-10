import 'package:commet/ui/atoms/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';

class SpaceHeader extends StatelessWidget {
  const SpaceHeader(this.space, {super.key});
  final Space space;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(s(10.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(space.displayName, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
