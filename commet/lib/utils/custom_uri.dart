import 'package:commet/config/build_config.dart';

class CustomURI {
  static CustomURI? parse(String text) {
    Uri? uri;
    try {
      uri = Uri.parse(text);
    } catch (exception) {
      return null;
    }

    if (uri.scheme != BuildConfig.appSchema) {
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

    if (uri.host == "accept_call") {
      if ([
        "room_id",
        "client_id",
        "call_id"
      ].any((element) => uri!.queryParameters.containsKey(element) == false)) {
        return null;
      }

      return AcceptCallUri(
          roomId: uri.queryParameters["room_id"]!,
          callId: uri.queryParameters["call_id"]!,
          clientId: uri.queryParameters["client_id"]!);
    }

    if (uri.host == "decline_call") {
      if ([
        "room_id",
        "client_id",
        "call_id"
      ].any((element) => uri!.queryParameters.containsKey(element) == false)) {
        return null;
      }

      return DeclineCallUri(
          roomId: uri.queryParameters["room_id"]!,
          callId: uri.queryParameters["call_id"]!,
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
        scheme: BuildConfig.appSchema,
        host: "open_room",
        queryParameters: {"room_id": roomId, "client_id": clientId}).toString();
  }
}

class AcceptCallUri implements CustomURI {
  final String roomId;
  final String clientId;
  final String callId;

  AcceptCallUri(
      {required this.roomId, required this.clientId, required this.callId});

  @override
  String toString() {
    return Uri(
        scheme: BuildConfig.appSchema,
        host: "accept_call",
        queryParameters: {
          "room_id": roomId,
          "client_id": clientId,
          "call_id": callId
        }).toString();
  }
}

class DeclineCallUri implements CustomURI {
  final String roomId;
  final String clientId;
  final String callId;

  DeclineCallUri(
      {required this.roomId, required this.clientId, required this.callId});

  @override
  String toString() {
    return Uri(
        scheme: BuildConfig.appSchema,
        host: "decline_call",
        queryParameters: {
          "room_id": roomId,
          "client_id": clientId,
          "call_id": callId
        }).toString();
  }
}

class SsoLoginUri implements CustomURI {
  SsoLoginUri();

  @override
  String toString() {
    return Uri(
        scheme: BuildConfig.appSchema,
        host: "login",
        queryParameters: {}).toString();
  }
}
