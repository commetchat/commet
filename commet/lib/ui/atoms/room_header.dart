import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as t;
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';

import '../../client/client.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room,
      {super.key, this.onTap, this.startCall, this.showCallButton = false});
  final Room room;
  final bool showCallButton;
  final Function()? onTap;
  final Function()? startCall;

  @override
  Widget build(BuildContext context) {
    bool isDirectMessage = room.client
            .getComponent<DirectMessagesComponent>()
            ?.isRoomDirectMessage(room) ??
        false;

    return m.Material(
      color: m.Colors.transparent,
      child: m.InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Row(
                children: [
                  SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        isDirectMessage
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
              if (showCallButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Row(
                    children: [
                      t.IconButton(
                        icon: m.Icons.call,
                        size: 20,
                        onPressed: startCall,
                      )
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
