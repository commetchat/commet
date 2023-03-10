import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';
import 'background.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Background.surface(
      context,
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2, width: s(1.5)))),
        child: Padding(
          padding: EdgeInsets.all(s(10.0)),
          child: Row(
            children: [
              SizedBox(
                  width: s(40),
                  height: s(40),
                  child: Icon(
                    Icons.tag,
                  )),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.displayName, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
