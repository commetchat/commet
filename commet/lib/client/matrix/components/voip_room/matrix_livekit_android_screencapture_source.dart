import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MatrixLivekitAndroidScreencaptureSource implements ScreenCaptureSource {
  static Future<ScreenCaptureSource?> getCaptureSource(
      BuildContext context) async {
    if (PlatformUtils.isAndroid) {
      final permission = await Helper.requestCapturePermission();
      if (permission == false) {
        AdaptiveDialog.show(context, builder: (context) => Placeholder());
        return null;
      }

      requestBackgroundPermission([bool isRetry = false]) async {
        // Required for android screenshare.
        try {
          bool hasPermissions = await FlutterBackground.hasPermissions;

          const androidConfig = FlutterBackgroundAndroidConfig(
            notificationTitle: 'Screen Sharing',
            notificationText: 'Commet is sharing the screen.',
            notificationImportance: AndroidNotificationImportance.normal,
            notificationIcon:
                AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          );

          if (!isRetry) {
            hasPermissions = await FlutterBackground.initialize(
                androidConfig: androidConfig);
          }
          if (hasPermissions &&
              !FlutterBackground.isBackgroundExecutionEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
        } catch (e) {
          if (!isRetry) {
            return await Future<void>.delayed(const Duration(seconds: 1),
                () => requestBackgroundPermission(true));
          }
          print('could not publish video: $e');
        }
      }

      await requestBackgroundPermission();

      return MatrixLivekitAndroidScreencaptureSource();
    }

    return null;
  }
}
