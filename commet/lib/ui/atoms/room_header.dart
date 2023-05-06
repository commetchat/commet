import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/client.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key, this.onTap});
  final Room room;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Tile(
      borderBottom: true,
      child: m.Material(
        child: m.InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      room.isDirectMessage
                          ? m.Icons.alternate_email_rounded
                          : m.Icons.tag,
                    )),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    m.Text(room.displayName,
                        style: m.Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
