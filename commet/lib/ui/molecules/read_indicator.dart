import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/room.dart';

class ReadIndicator extends StatelessWidget {
  const ReadIndicator(
      {required this.room, required this.users, this.onTap, super.key});
  final Room room;
  final Function()? onTap;
  final List<String> users;

  @override
  Widget build(BuildContext context) {
    var max = 4;
    var diff = users.length - 3;

    return Material(
      color: Colors.transparent,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diff > 0) tiamat.Text.labelLow("+$diff "),
            InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  for (int i = 0; i < users.length && i < max; i++)
                    buildEntry(i, context),
                ],
              ),
            )
          ]),
    );
  }

  Widget buildEntry(int index, BuildContext context) {
    var member = room.getMemberOrFallback(users[index]);
    return Padding(
      padding: EdgeInsets.fromLTRB(index.toDouble() * 8, 0, 0, 0),
      child: tiamat.Avatar(
        border: BoxBorder.all(
            color: ColorScheme.of(context).surfaceContainerLow,
            width: 2,
            strokeAlign: 0.5),
        radius: 8,
        image: member.avatar,
        placeholderColor: member.defaultColor,
        placeholderText: member.displayName,
      ),
    );
  }
}
