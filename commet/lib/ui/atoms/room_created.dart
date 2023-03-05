import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/room.dart';

class RoomCreated extends StatelessWidget {
  const RoomCreated(this.room, {super.key});
  final Room room;
  @override
  Widget build(BuildContext context) {
    print(room.avatar);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 200, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Avatar.large(
              image: room.avatar,
              placeholderText: room.displayName,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to ${room.displayName}!",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      "This is the beginning of the end...",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
