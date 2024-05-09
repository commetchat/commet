import 'dart:async';

import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/ui/pages/matrix/room_address_settings/matrix_room_address_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MatrixRoomAddressSettings extends StatefulWidget {
  const MatrixRoomAddressSettings(this.matrixRoom, {super.key});
  final Room matrixRoom;
  @override
  State<MatrixRoomAddressSettings> createState() =>
      _MatrixRoomAddressSettingsState();
}

class _MatrixRoomAddressSettingsState extends State<MatrixRoomAddressSettings> {
  List<String>? aliases;
  List<String>? publishedAliases;
  String? mainAlias;
  StreamController<String?> onMainAliasChanged = StreamController();

  @override
  void initState() {
    getRoomAliases();
    mainAlias = widget.matrixRoom.canonicalAlias;
    if (mainAlias == "") {
      mainAlias = null;
    }
    super.initState();
  }

  Future<void> getRoomAliases() async {
    var newAliases = List<String>.empty(growable: true);
    var newPublishedAliases = List<String>.empty(growable: true);

    try {
      var result = await widget.matrixRoom.client.request(
        RequestType.GET,
        '/client/unstable/org.matrix.msc2432/rooms/${Uri.encodeComponent(widget.matrixRoom.id)}/aliases',
      );

      newAliases.addAll(List<String>.from(result['aliases'] as Iterable));
    } catch (_) {}

    var altAliases = widget.matrixRoom.states["m.room.canonical_alias"]?[""]
        ?.content["alt_aliases"] as Iterable?;

    if (altAliases != null) {
      newAliases.addAll(List<String>.from(altAliases)
          .where((element) => newAliases.contains(element) == false));

      newPublishedAliases.addAll(List<String>.from(altAliases)
          .where((element) => newPublishedAliases.contains(element) == false));
    }

    if (widget.matrixRoom.canonicalAlias != "" &&
        newAliases.contains(widget.matrixRoom.canonicalAlias) == false) {
      newAliases.add(widget.matrixRoom.canonicalAlias);
    }

    if (newPublishedAliases.contains(widget.matrixRoom.canonicalAlias) ==
        false) {
      newPublishedAliases.add(widget.matrixRoom.canonicalAlias);
    }

    setState(() {
      aliases = newAliases;
      publishedAliases = newPublishedAliases;
    });
  }

  String get userHomeserverPart =>
      widget.matrixRoom.client.userID!.split(":").last;

  @override
  Widget build(BuildContext context) {
    if (aliases == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return MatrixRoomAddressSettingsView(
      aliases!,
      publishedAliases: publishedAliases!,
      mainAlias: mainAlias,
      userHomeserver: userHomeserverPart,
      canAddLocalAlias: true,
      mainAliasChangedStream: onMainAliasChanged.stream,
      isAliasAvailable: isAliasAvailable,
      createAlias: createAlias,
      deleteAlias: deleteAlias,
      setMainAlias: setMainAlias,
      publishAlias: publishAlias,
      unpublishAlias: unpublishAlias,
      canChangeMainAlias:
          widget.matrixRoom.canChangeStateEvent("m.room.canonical_alias"),
    );
  }

  Future<bool> isAliasAvailable(String alias) async {
    var fullAlias = "#$alias:$userHomeserverPart";
    return await widget.matrixRoom.client.isRoomAliasAvailable(fullAlias);
  }

  Future<String?> createAlias(String alias) async {
    var fullAlias = "#$alias:$userHomeserverPart";
    try {
      await widget.matrixRoom.client
          .setRoomAlias(fullAlias, widget.matrixRoom.id);

      setState(() {
        aliases?.add(fullAlias);
      });
      return fullAlias;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAlias(String alias) async {
    try {
      await widget.matrixRoom.client.deleteRoomAlias(alias);

      setState(() {
        aliases?.remove(alias);
        publishedAliases?.remove(alias);
      });
      return true;
    } catch (exception) {
      return false;
    }
  }

  Future<bool> setMainAlias(String alias) async {
    await setAsMainAlias(alias);
    updatePublishedAliases();
    setState(() {
      mainAlias = alias;
    });

    return true;
  }

  void updatePublishedAliases() {
    var result = List<String>.empty(growable: true);

    var altAliases = widget.matrixRoom.states["m.room.canonical_alias"]?[""]
        ?.content["alt_aliases"] as Iterable?;

    if (altAliases != null) {
      result.addAll(List<String>.from(altAliases));
    }

    result.add(widget.matrixRoom.canonicalAlias);

    setState(() {
      publishedAliases = result;
    });
  }

  Future<void> publishAlias(String newPublishedAlias) async {
    var state =
        widget.matrixRoom.states["m.room.canonical_alias"]?[""]?.content;

    state ??= {};

    if (state.containsKey("alt_aliases") == false) {
      state["alt_aliases"] = List<dynamic>.empty(growable: true);
    }

    var list = state["alt_aliases"] as List<dynamic>;
    if (list.contains(newPublishedAlias) == false) {
      list.add(newPublishedAlias);
    }

    await widget.matrixRoom.client.setRoomStateWithKey(
        widget.matrixRoom.id, EventTypes.RoomCanonicalAlias, "", state);

    setState(() {
      publishedAliases?.add(newPublishedAlias);
    });
  }

  Future<void> unpublishAlias(String alias) async {
    var state =
        widget.matrixRoom.states["m.room.canonical_alias"]?[""]?.content;

    if (state == null) {
      return;
    }

    if (state.containsKey("alt_aliases") == false) {
      return;
    }

    var list = state["alt_aliases"] as List<dynamic>;
    list.remove(alias);

    if (state["alias"] == alias) {
      state.remove("alias");
      setState(() {
        mainAlias = null;
        onMainAliasChanged.add(null);
      });
    }

    await widget.matrixRoom.client.setRoomStateWithKey(
        widget.matrixRoom.id, EventTypes.RoomCanonicalAlias, "", state);

    setState(() {
      publishedAliases?.remove(alias);
    });
  }

  Future<void> setAsMainAlias(String newMainAlias) async {
    var state =
        widget.matrixRoom.states["m.room.canonical_alias"]?[""]?.content;

    state ??= {};

    state["alias"] = newMainAlias;

    await widget.matrixRoom.client.setRoomStateWithKey(
        widget.matrixRoom.id, EventTypes.RoomCanonicalAlias, "", state);

    onMainAliasChanged.add(newMainAlias);
  }
}
