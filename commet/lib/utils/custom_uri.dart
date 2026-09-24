import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:tiamat/config/style/theme_json_converter.dart';
import 'package:win32_registry/win32_registry.dart';

class CustomURI {
  static StreamController<Uri> _onLinked = StreamController.broadcast();

  static void init() {
    final appLinks = AppLinks();

    appLinks.uriLinkStream.listen((uri) {
      Log.i("Received custom app link: ${uri}");
      _onLinked.add(uri);
    });

    if (PlatformUtils.isWindows) {
      register("commetchat");
    }
  }

  static Future<void> register(String scheme) async {
    String appPath = Platform.resolvedExecutable;

    String protocolRegKey = 'Software\\Classes\\$scheme';
    RegistryValue protocolRegValue = const RegistryValue.string(
      'URL Protocol',
      '',
    );
    String protocolCmdRegKey = 'shell\\open\\command';
    RegistryValue protocolCmdRegValue = RegistryValue.string(
      '',
      '"$appPath" "%1"',
    );

    final regKey = Registry.currentUser.createKey(protocolRegKey);
    regKey.createValue(protocolRegValue);
    regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
  }

  static Stream<Uri> get onLinked => _onLinked.stream;

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

    if (uri.host == "add_widget") {
      var url = uri.queryParameters.tryGet<String>("url");
      var avatar = uri.queryParameters.tryGet<String>("avatar");
      var widgetType = uri.queryParameters.tryGet<String>("type");
      var widgetName = uri.queryParameters.tryGet<String>("name");
      var preview = uri.queryParameters.tryGet<String>("preview");

      if (url != null) {
        return AddWidgetURI(
            widgetUrl: Uri.decodeComponent(url),
            widgetAvatarMxc:
                avatar != null ? Uri.decodeComponent(avatar) : null,
            widgetName:
                widgetName != null ? Uri.decodeComponent(widgetName) : null,
            previewMxc: preview != null && preview.startsWith("mxc") == true
                ? Uri.decodeComponent(preview)
                : null,
            widgetType:
                widgetType != null ? Uri.decodeComponent(widgetType) : null);
      }
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

class AddWidgetURI implements CustomURI {
  final String widgetUrl;
  final String? widgetType;
  final String? widgetAvatarMxc;
  final String? widgetName;
  final String? previewMxc;

  AddWidgetURI(
      {required this.widgetUrl,
      this.previewMxc,
      this.widgetName,
      this.widgetType,
      this.widgetAvatarMxc});

  @override
  String toString() {
    return Uri(
        scheme: BuildConfig.appSchema,
        host: "add_widget",
        queryParameters: {
          "url": widgetUrl,
          if (widgetType != null) "type": widgetType,
          if (widgetAvatarMxc != null) "avatar": widgetAvatarMxc!,
        }).toString();
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
