import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as t;

import '../../client/client.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key, this.onTap});
  final Room room;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return t.Tile(
      borderBottom: true,
      child: m.Material(
        child: m.InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          room.isDirectMessage
                              ? m.Icons.alternate_email_rounded
                              : m.Icons.tag,
                        )),
                    Flexible(
                      child: m.Text(
                        room.displayName,
                        style: m.Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Row(
                    children: [
                      t.IconButton(
                        icon: m.Icons.call,
                        size: 20,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
