import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/widgets.dart';

class DirectMessageList extends StatefulWidget {
  const DirectMessageList(
      {required this.directMessages, this.onSelected, super.key});
  final List<Room> directMessages;
  @override
  State<DirectMessageList> createState() => _DirectMessageListState();
  final Function(int index)? onSelected;
}

class _DirectMessageListState extends State<DirectMessageList> {
  int numDMs = 0;
  int selectedIndex = -1;

  @override
  void initState() {
    numDMs = widget.directMessages.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      initialItemCount: numDMs,
      itemBuilder: (context, index, animation) {
        var room = widget.directMessages[index];
        return UserPanelView(
          displayName: room.displayName,
          avatar: room.avatar,
          padding: const EdgeInsets.fromLTRB(4, 2, 0, 2),
          onClicked: () {
            setState(() {
              selectedIndex = index;
              widget.onSelected?.call(index);
            });
          },
        );
      },
    );
  }
}
