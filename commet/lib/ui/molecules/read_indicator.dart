import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/room.dart';

class ReadIndicator extends StatelessWidget {
  const ReadIndicator(
      {required this.room, required this.users, this.onTap, super.key});
  final Room room;
  final Function()? onTap;
  final List<String> users;

  static const int maxItems = 4;

  @override
  Widget build(BuildContext context) {
    var diff = users.length - maxItems;
    return Material(
      color: Colors.transparent,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  for (int i = 0; i < users.length && i < maxItems; i++)
                    buildEntry(i, context, fade: diff > 0),
                ],
              ),
            )
          ]),
    );
  }

  Widget buildEntry(int index, BuildContext context, {bool fade = false}) {
    var member = room.getMemberOrFallback(users[index]);
    return Opacity(
      opacity: fade ? index / (maxItems - 1) : 1.0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(index.toDouble() * 6, 0, 0, 0),
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
      ),
    );
  }
}
