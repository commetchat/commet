import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../../client/client.dart';

class ChatPageState extends StatefulWidget {
  const ChatPageState({required this.directMessageRooms, super.key});

  final List<Room> directMessageRooms;

  @override
  State<ChatPageState> createState() => ChatPageStateState();
}

class ChatPageStateState extends State<ChatPageState> {
  late List<Room> directMessageRooms;
  Room? selectedRoom = null;
  Space? selectedSpace = null;

  @override
  void initState() {
    directMessageRooms = widget.directMessageRooms;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
