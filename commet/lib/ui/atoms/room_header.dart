import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/client.dart';
import '../../config/app_config.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Tile(
      borderBottom: true,
      child: Padding(
          padding: EdgeInsets.all(s(10.0)),
          child: Row(
            children: [
              SizedBox(
                  width: s(40),
                  height: s(40),
                  child: Icon(
                    room.isDirectMessage ? m.Icons.alternate_email_rounded : m.Icons.tag,
                  )),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  m.Text(room.displayName, style: m.Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
    );
  }
}
