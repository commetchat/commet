import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/session/matrix_session_view.dart';
import 'package:flutter/widgets.dart';

import 'package:matrix/matrix.dart';

import '../../../../../../matrix/verification/matrix_verification_page.dart';

class MatrixSession extends StatefulWidget {
  const MatrixSession(this.device, this.matrixClient,
      {super.key, this.onUpdated});
  final Device device;
  final Client matrixClient;
  final Function? onUpdated;

  @override
  State<MatrixSession> createState() => _MatrixSessionState();
}

class _MatrixSessionState extends State<MatrixSession> {
  Function()? previousOnUpdate;

  @override
  Widget build(BuildContext context) {
    return MatrixSessionView(
      deviceId: widget.device.deviceId,
      displayName: widget.device.displayName,
      lastSeenIp: widget.device.lastSeenIp,
      lastSeenTimestamp: widget.device.lastSeenTs,
      verified: isVerified(),
      isThisDevice: isCurrentDevice(),
      beginVerification: beginVerification,
      removeSession: removeSession,
    );
  }

  bool isVerified() {
    var keys = widget.matrixClient.userDeviceKeys[widget.matrixClient.userID]
        ?.deviceKeys[widget.device.deviceId];
    return keys?.verified ?? false;
  }

  bool isCurrentDevice() {
    return widget.device.deviceId == widget.matrixClient.deviceID;
  }

  void beginVerification() {
    var keys = widget.matrixClient.userDeviceKeys[widget.matrixClient.userID]
        ?.deviceKeys[widget.device.deviceId];
    var request = keys!.startVerification();
    previousOnUpdate = request.onUpdate;
    request.onUpdate = onRequestUpdate;

    AdaptiveDialog.show(context,
        builder: (_) => MatrixVerificationPage(request: request),
        title: "Verification Request");
  }

  void onRequestUpdate() {
    previousOnUpdate?.call();
    setState(() {});
  }

  void removeSession() async {
    await widget.matrixClient.uiaRequestBackground((auth) async {
      await widget.matrixClient
          .deleteDevice(widget.device.deviceId, auth: auth);
      widget.onUpdated?.call();
    });
  }
}
