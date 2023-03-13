import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../client/room.dart';

class RoomCreated extends StatelessWidget {
  const RoomCreated(this.room, {super.key});
  final Room room;
  @override
  Widget build(BuildContext context) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.largeTitle(
                    "Welcome to ${room.displayName}!",
                  ),
                  const tiamat.Text.labelEmphasised(
                    "This is the beginning of the end...",
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
