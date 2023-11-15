class CustomURI {
  static CustomURI? parse(String text) {
    Uri? uri;
    try {
      uri = Uri.parse(text);
    } catch (exception) {
      return null;
    }

    if (uri.scheme != "commet") {
      return null;
    }

    if (uri.host == "open_room") {
      if ([
        "room_id",
        "client_id"
      ].any((element) => uri!.queryParameters.containsKey(element) == false)) {
        return null;
      }

      return OpenRoomURI(
          roomId: uri.queryParameters["room_id"]!,
          clientId: uri.queryParameters["client_id"]!);
    }

    return null;
  }
}

class OpenRoomURI implements CustomURI {
  final String roomId;
  final String clientId;

  OpenRoomURI({required this.roomId, required this.clientId});

  @override
  String toString() {
    return Uri(
        scheme: "commet",
        host: "open_room",
        queryParameters: {"room_id": roomId, "client_id": clientId}).toString();
  }
}
