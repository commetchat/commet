import 'package:commet/client/client.dart';
import 'package:flutter/widgets.dart';

import 'add_space_or_room_view.dart';

enum AddSpaceOrRoomMode {
  createOrJoinSpace,
  createOrJoinRoom,
  createOrExistingRoom,
}

class AddSpaceOrRoom extends StatefulWidget {
  const AddSpaceOrRoom({
    super.key,
    this.eligibleRooms,
    this.client,
    this.clients,
    this.onRoomCreated,
    this.onSpaceCreated,
    this.joinSpace,
    this.onRoomsSelected,
    this.mode = AddSpaceOrRoomMode.createOrJoinSpace,
  });
  final List<Client>? clients;
  final Client? client;
  final AddSpaceOrRoomMode mode;
  final List<Room>? eligibleRooms;
  final Function(Iterable<Room> rooms)? onRoomsSelected;
  final Function(Room room)? onRoomCreated;
  final Function(Space space)? onSpaceCreated;

  final Function(Client client, String address)? joinSpace;
  @override
  State<AddSpaceOrRoom> createState() => AddSpaceOrRoomState();

  const AddSpaceOrRoom.askCreateOrExistingRoom(
      {Key? key,
      required List<Room> rooms,
      this.client,
      this.clients,
      this.onRoomCreated,
      this.joinSpace,
      this.onSpaceCreated,
      this.onRoomsSelected})
      : mode = AddSpaceOrRoomMode.createOrExistingRoom,
        eligibleRooms = rooms,
        super(key: key);
}

class AddSpaceOrRoomState extends State<AddSpaceOrRoom> {
  void create(Client client, String name, RoomVisibility visibility,
      bool enableE2EE) async {
    if (mounted) {
      Navigator.of(context).pop();
    }

    switch (widget.mode) {
      case AddSpaceOrRoomMode.createOrJoinSpace:
        var space = await client.createSpace(name, visibility);
        widget.onSpaceCreated?.call(space);
        break;
      case AddSpaceOrRoomMode.createOrJoinRoom:
      case AddSpaceOrRoomMode.createOrExistingRoom:
        var room =
            await client.createRoom(name, visibility, enableE2EE: enableE2EE);
        widget.onRoomCreated?.call(room);

        break;
    }
  }

  void joinSpace(Client client, String address) async {
    await client.joinSpace(address);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddSpaceOrRoomView(
      clients: widget.clients,
      client: widget.client,
      onCreate: create,
      onJoin: joinSpace,
      roomMode: widget.mode == AddSpaceOrRoomMode.createOrJoinRoom ||
          widget.mode == AddSpaceOrRoomMode.createOrExistingRoom,
      rooms: widget.eligibleRooms,
      initialPhase: widget.mode == AddSpaceOrRoomMode.createOrExistingRoom
          ? AddSpaceOrRoomPhase.askCreateOrExisting
          : null,
      onRoomsSelected: widget.onRoomsSelected,
    );
  }
}
