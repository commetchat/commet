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
    this.createRoom,
    this.createSpace,
    this.joinRoom,
    this.joinSpace,
    this.onRoomsSelected,
    this.mode = AddSpaceOrRoomMode.createOrJoinSpace,
  });
  final List<Client>? clients;
  final Client? client;
  final AddSpaceOrRoomMode mode;
  final List<Room>? eligibleRooms;
  final Function(Iterable<Room> rooms)? onRoomsSelected;
  final Future<void> Function(Client client, String name,
      RoomVisibility visibility, bool enableE2EE)? createRoom;

  final Future<void> Function(Client client, String name,
      RoomVisibility visibility, bool enableE2EE)? createSpace;

  final Function(Client client, String address)? joinRoom;
  final Function(Client client, String address)? joinSpace;
  @override
  State<AddSpaceOrRoom> createState() => AddSpaceOrRoomState();

  const AddSpaceOrRoom.askCreateOrExistingRoom(
      {Key? key,
      List<Room>? rooms,
      this.client,
      this.clients,
      this.createRoom,
      this.onRoomsSelected})
      : mode = AddSpaceOrRoomMode.createOrExistingRoom,
        eligibleRooms = rooms,
        createSpace = null,
        joinRoom = null,
        joinSpace = null,
        super(key: key);
}

class AddSpaceOrRoomState extends State<AddSpaceOrRoom> {
  Future<void> create(Client client, String name, RoomVisibility visibility,
      bool enableE2EE) async {
    switch (widget.mode) {
      case AddSpaceOrRoomMode.createOrJoinSpace:
        await widget.createSpace?.call(client, name, visibility, enableE2EE);
        break;
      case AddSpaceOrRoomMode.createOrJoinRoom:
      case AddSpaceOrRoomMode.createOrExistingRoom:
        await widget.createRoom?.call(client, name, visibility, enableE2EE);
        break;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> join(Client client, String address) async {
    switch (widget.mode) {
      case AddSpaceOrRoomMode.createOrJoinSpace:
        await widget.joinSpace?.call(client, address);
        break;
      case AddSpaceOrRoomMode.createOrJoinRoom:
      case AddSpaceOrRoomMode.createOrExistingRoom:
        await widget.joinRoom?.call(client, address);
        break;
    }

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
      onJoin: join,
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
