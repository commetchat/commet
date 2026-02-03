import 'dart:convert';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix_api_lite.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtils {
  static Future<void> open(Uri uri,
      {String? clientId,
      String? contextRoomId,
      BuildContext? context,
      bool filterTrackingParameters = true}) async {
    if (uri.host == "matrix.to") {
      var result = MatrixClient.parseMatrixLink(uri);

      if (result != null && clientId != null) {
        switch (result.$1) {
          case MatrixLinkType.room:
            return EventBus.openRoom.add((result.$3, clientId));
          case MatrixLinkType.user:
            return EventBus.openUserProfile
                .add((result.$2, clientId, contextRoomId));
          case MatrixLinkType.roomAlias:
            return EventBus.openRoom.add((result.$3, clientId));
        }
      }
    }

    if (!(uri.scheme == "http" || uri.scheme == "https")) {
      return;
    }

    var openUrl = uri;

    var cleanedUrl = await cleanTrackingParameters(uri);

    if (cleanedUrl.toString() != uri.toString()) {
      if (context != null) {
        var confirm = await AdaptiveDialog.confirmation(context,
            title: "Open Link",
            confirmationText: "Open",
            cancelText: "Open Original Link",
            prompt:
                "This link contained trackers, which have been removed. Navigate to '$cleanedUrl'?");

        if (confirm == null) return;

        if (confirm == true) {
          openUrl = cleanedUrl;
        }
      }
    } else {
      if (context != null) {
        if (await AdaptiveDialog.confirmation(context,
                title: "Open Link",
                confirmationText: "Open",
                cancelText: "Cancel",
                prompt: "Navigate to '$uri'?") !=
            true) {
          return;
        }
      }
    }

    Log.d("Opening Link: $openUrl");

    launchUrl(openUrl, mode: LaunchMode.externalApplication);
  }

  static Map<String, UrlParameterRule> parameterRules = {};

  static Future<void> init() async {
    var data = await rootBundle.loadString('assets/data/clearurls.json');
    var json = jsonDecode(data);

    var providers = json["providers"] as Map<String, dynamic>;

    for (var key in providers.entries) {
      parameterRules[key.key] = UrlParameterRule.fromJson(
          key.value as Map<String, dynamic>, key.key)!;
    }
  }

  static Future<Uri> cleanTrackingParameters(Uri uri) async {
    if (parameterRules.isEmpty) await init();

    Uri? result = uri;
    for (var value in parameterRules.values) {
      result = value.process(result!);

      if (result == null) {
        throw Exception("Uri processing returned null");
      }
    }

    return result!;
  }
}

class UrlParameterRule {
  /// The urlPattern is a regular expression, that must match every URL that should be affected by the specified rules, exceptions, or redirections of the provider.
  String urlPattern;

  String label;

  /// The completeProvider is a boolean, that determines if every URL that matches the urlPattern will be blocked. If you want to specify rules, exceptions, and/or redirections, the value of completeProvider must be false
  bool completeProvider;

  List<String>? rules;

  List<String>? referralMarketing;

  /// The exceptions property is also a JSON array. Every element in this array is a regular expression, that matches a URL. If ClearURLs found a URL, that matches an exception, no further processing on this URL is done.
  List<String>? exceptions;

  List<String>? rawRules;

  List<String>? redirections;

  bool? forceRedirection;

  UrlParameterRule({
    required this.urlPattern,
    required this.label,
    required this.completeProvider,
    this.rules,
    this.referralMarketing,
    this.exceptions,
    this.rawRules,
    this.redirections,
    this.forceRedirection,
  });

  static UrlParameterRule? fromJson(Map<String, dynamic> data, String label) {
    var urlPattern = data["urlPattern"] as String;
    var completeProvider = data["completeProvider"] as bool;

    return UrlParameterRule(
      urlPattern: urlPattern,
      label: label,
      completeProvider: completeProvider,
      rules: data.tryGetList<String>("rules"),
      referralMarketing: data.tryGetList<String>("rules"),
      exceptions: data.tryGetList<String>("exceptions"),
      rawRules: data.tryGetList<String>("rawRules"),
      redirections: data.tryGetList<String>("redirections"),
      forceRedirection: data.tryGet<bool>("forceRedirection"),
    );
  }

  Uri? process(Uri uri) {
    var str = uri.toString();
    var pattern = RegExp(urlPattern);
    if (!pattern.hasMatch(str)) {
      return uri;
    }

    if (exceptions != null) {
      for (var exception in exceptions!) {
        var exceptionpattern = RegExp(exception);
        if (exceptionpattern.hasMatch(str)) {
          print("[$label] Skipping ${uri} due to exception: $exception");
          return uri;
        }
      }
    }

    if (rawRules != null) {
      for (var ruleStr in rawRules!) {
        var rule = RegExp(ruleStr);
        str = str.replaceAll(rule, "");
      }
    }

    var result = Uri.parse(str);

    if (rules != null) {
      for (var rule in rules!) {
        var regex = RegExp("^$rule\$");

        Map<String, String> params = Map.from(result.queryParameters);
        for (var param in params.keys.toList()) {
          if (regex.hasMatch(param)) {
            params.remove(param);
          }
        }

        result = result.replace(queryParameters: params);
      }
    }

    return Uri(
      scheme: result.scheme,
      userInfo: result.userInfo,
      host: result.host,
      port: result.port,
      path: result.path,
      queryParameters:
          result.queryParameters.isEmpty ? null : result.queryParameters,
      fragment: result.fragment.isEmpty ? null : result.fragment,
    );
  }
}
