import 'package:commet/config/platform_utils.dart';
import 'package:commet/utils/links/executor/link_executor_open_uri.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

abstract class LinkExecutor {
  List<String> platforms;
  Map<String, dynamic> data;

  LinkExecutor(this.platforms, this.data);

  @mustCallSuper
  Future<bool> canHandleLink(Uri uri) async {
    if (PlatformUtils.isLinux && !platforms.contains("linux")) return false;
    if (PlatformUtils.isWindows && !platforms.contains("windows")) return false;
    if (PlatformUtils.isAndroid && !platforms.contains("android")) return false;
    if (PlatformUtils.isWeb && !platforms.contains("web")) return false;

    return true;
  }

  String getDescription(Uri uri);

  Future<void> execute(Uri uri);

  static LinkExecutor? fromJson(String type, Map<String, dynamic> data) {
    List<String>? platforms = data.tryGetList("platforms");
    if (platforms == null) return null;

    return switch (type) {
      "openUri" => LinkExecutorOpenUri(platforms, data),
      _ => null,
    };
  }
}
