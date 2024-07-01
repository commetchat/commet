import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';

import '../../client/client.dart';

class RoomHeader extends StatelessWidget {
  const RoomHeader(this.room, {super.key, this.onTap});
  final Room room;
  final Function()? onTap;

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
        ),
      ),
    );
  }
}
