import 'dart:convert';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:convert/convert.dart';

class MacosNotifier implements Notifier {
  static const String _channelName = "PushNotificationChannel";
  static const MethodChannel _channel = MethodChannel(_channelName);

  static String? deviceToken;
  static String? hexDeviceTokenUpper;
  static String? hexDeviceTokenLower;
  static String? base64DeviceToken;
  static const String pushGateway =
      "https://sygnal.spacebinoculars.matrix.town";
  static const bool deviceTokenIsHex = false;

  @override
  bool hasPermission = false;

  @override
  bool get needsToken => true;

  @override
  bool get enabled => true;

  @override
  Future<void> init() async {
    preferences.setPushGateway(pushGateway);
    await requestPermission().then((value) async {
      await registerDevice().then((_) async {});
    });
  }

  @override
  Future<void> notify(NotificationContent notification) async {}

  static Future<void> requestPushNotificationPermission() async {
    try {
      await _channel.invokeMethod("requestNotificationPermissions");
    } on PlatformException catch (e) {
      Log.e("Failed to get permission with message $e.message");
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await MacosNotifier.requestPushNotificationPermission();
      return true;
    } on PlatformException catch (e) {
      Log.e("Error Getting Permission: $e.message");
      return false;
    }
  }

  static Future<void> registerDevice() async {
    try {
      await _channel.invokeMethod("registerForPushNotifications");
    } on PlatformException {
      return;
    }
  }

  static Future<String?> retriveDeviceToken() async {
    try {
      String? token =
          await _channel.invokeMethod<String>("retrieveDeviceToken");
      return token;
    } on PlatformException catch (e) {
      Log.e("Error on token retrieval: $e.message");
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      String? token = await MacosNotifier.retriveDeviceToken();
      if (deviceTokenIsHex) {
        return token!.toLowerCase();
      }
      return base64.encode(hex.decode(token!));
    } on PlatformException {
      Log.i("Failed to get token, device token is $deviceToken");
      if (deviceTokenIsHex) {
        return hexDeviceTokenLower;
      }
      return base64DeviceToken;
    }
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    var extraData = {
      "default_payload": {
        "aps": {
          "mutable-content": 1,
          "content-available": 1,
          "alert": {"loc-key": "SINGLE_UNREAD", "loc-args": []}
        },
        "hex_device_token": hexDeviceTokenLower,
      },
    };
    return extraData;
  }

  static handlerPushNotificationData({required BuildContext context}) async {
    _channel.setMethodCallHandler((call) async {
      var callMethod = call.method;
      Log.i("Channel Called with method $callMethod");
      if (call.method == "onPushNotification") {
        Log.i("in onPushNotification");
        final eventId = call.arguments['event_id'];
        final roomId = call.arguments['room_id'];

        if (eventId == null || roomId == null) {
          return;
        }

        var client = clientManager!.clients
            .firstWhere((element) => element.hasRoom(roomId));

        EventBus.openRoom.add((roomId, client.identifier));
      } else if (call.method == "didRegister") {
        Log.i("Registered");
        hexDeviceTokenUpper = call.arguments as String;
        Log.i("Received token $hexDeviceTokenUpper");
        base64DeviceToken = base64.encode(hex.decode(hexDeviceTokenUpper!));
        Log.i("Base64-encoded token is $base64DeviceToken");
        hexDeviceTokenLower = hexDeviceTokenUpper!.toLowerCase();
        Log.i("Lowercase Token is $hexDeviceTokenLower");
        if (deviceTokenIsHex) {
          deviceToken = hexDeviceTokenLower;
        } else {
          deviceToken = base64DeviceToken;
        }
        await PushNotificationComponent.updateAllPushers();
      } else if (call.method == "onBackgroundNotification") {
        Log.i("in onBackgroundNotification()");
        var callArguments = call.arguments;
        Log.i("Message Arguments: $callArguments");
      }
    });
  }

  @override
  Future<void> clearNotifications(Room room) async {
    return;
  }
}
