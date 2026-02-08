import 'dart:convert';

import 'package:commet/utils/links/executor/link_executor.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

class SmartLinkHandling {
  static Future<bool> handleLink(Uri uri) async {
    return false;
  }

  static Future<SmartLinkHandler?> getHandler(Uri uri) async {
    var data = await rootBundle.loadString('assets/data/url_handlers.json');
    Map<String, dynamic> json = jsonDecode(data);

    Map<String, dynamic>? entry = json.tryGetMap(uri.host);

    if (entry == null) return null;

    return SmartLinkHandler.fromJson(entry);
  }
}

class SmartLinkHandler {
  String appName;
  List<LinkExecutor> executors;

  SmartLinkHandler({
    required this.appName,
    required this.executors,
  });

  static SmartLinkHandler? fromJson(Map<String, dynamic> data) {
    Map<String, dynamic>? appNameLocalizations =
        data.tryGetMap("appDisplayName");

    String? appName = appNameLocalizations?.tryGet("en");
    if (appName == null) return null;

    Map<String, dynamic>? actions = data.tryGetMap("actions");
    if (actions == null) return null;

    List<LinkExecutor> executors = List.empty(growable: true);
    for (var action in actions.entries) {
      var executor = LinkExecutor.fromJson(action.key, action.value);
      if (executor != null) {
        executors.add(executor);
      }
    }

    if (executors.isEmpty) return null;

    return SmartLinkHandler(appName: appName, executors: executors);
  }
}
