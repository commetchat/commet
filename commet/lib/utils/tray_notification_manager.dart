import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:commet/client/client_manager.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayNotificationManager {
  static const String _defaultTrayIconPath =
      'assets/images/app_icon/app_icon_rounded.png';

  static const String _cacheId = 'tray_icon_with_notification_badge.png';

  static String? _cachedIconPath;

  static StreamSubscription<void>? _syncNotificationSubscription;
  static Future<void> Function()? _onCloseApplication;

  static Future<void> init({
    required ClientManager? clientManager,
    required Future<void> Function() onCloseApplication,
  }) async {
    _onCloseApplication = onCloseApplication;

    await TrayManager.instance.setIcon(_defaultTrayIconPath);
    await _setupTrayMenu();
    TrayManager.instance.addListener(_TrayListener());

    _registerTrayNotificationListeners(clientManager);
  }

  static void _registerTrayNotificationListeners(ClientManager? clientManager) {
    _syncNotificationSubscription?.cancel();

    if (clientManager == null) {
      return;
    }

    _syncNotificationSubscription =
        clientManager.onSync.stream.listen(_onSyncNotificationUpdated);

    _onTrayNotificationStateChanged();
  }

  // Update tray icon during sync
  static void _onSyncNotificationUpdated(void _) {
    _onTrayNotificationStateChanged();
  }

  static Future<void> _onTrayNotificationStateChanged() async {
    var counts = NotificationUtils.getTrayNotificationCounts();
    var notificationCount = counts.$2;

    if (notificationCount == 0) {
      await TrayManager.instance.setIcon(_defaultTrayIconPath);
    } else {
      await _drawNotificationBadge();
    }
  }

  static Future<void> _drawNotificationBadge() async {
    if (_cachedIconPath != null && await File(_cachedIconPath!).exists()) {
      await TrayManager.instance.setIcon(_cachedIconPath!);
      return;
    }

    final cache = fileCache;
    if (cache == null) {
      Log.e('File cache is not initialized, cannot get or create cached tray icon with notification badge');
      return; // TrayManager.instance.setIcon expects a file on disk so cannot continue without caching the icon
    }

    var cached = await cache.getFile(_cacheId);
    if (cached != null) {
      _cachedIconPath = File.fromUri(cached).path;
      await TrayManager.instance.setIcon(_cachedIconPath!);
      return;
    }

    Log.i('No cached tray icon with notification badge found, creating new one');

    final baseIconBytes = await rootBundle.load(_defaultTrayIconPath);
    final codec = await ui.instantiateImageCodec(baseIconBytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final baseImage = frame.image;

    final size = Size(baseImage.width.toDouble(), baseImage.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(baseImage, Offset.zero, Paint());

    final badgeRadius = size.shortestSide / 6;
    final badgeCenter = Offset(size.width - badgeRadius, badgeRadius);
    final paint = Paint()
        ..color = Colors.red;
    canvas.drawCircle(badgeCenter, badgeRadius, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      Log.e('Failed to convert tray icon image to byte data');
      return;
    }
    final pngBytes = byteData.buffer.asUint8List();

    var savedUri = await cache.putFile(_cacheId, pngBytes);
    _cachedIconPath = File.fromUri(savedUri).path;

    Log.i('Saved new tray icon with notification badge to cache');

    await TrayManager.instance.setIcon(_cachedIconPath!);
  }

  static Future<void> _setupTrayMenu() async {
    final menu = [
      MenuItem(label: 'Commet', key: 'app_name', disabled: true),
      MenuItem.separator(),
      MenuItem(label: 'Open Commet', key: 'show'),
      MenuItem(label: 'Quit Commet', key: 'close'),
    ];
    await TrayManager.instance.setContextMenu(Menu(items: menu));
  }
}

class _TrayListener extends TrayListener {
  @override
  void onTrayIconMouseDown() {
    _showWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'close':
        _closeApplication();
        break;
    }
  }

  Future<void> _showWindow() async {
    if (await windowManager.isVisible()) {
      await windowManager.focus();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  Future<void> _closeApplication() async {
    await TrayNotificationManager._onCloseApplication?.call();
  }
}