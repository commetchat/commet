import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/style/theme_extensions.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2, width: 1.5))),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.tag,
                    weight: 3,
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
