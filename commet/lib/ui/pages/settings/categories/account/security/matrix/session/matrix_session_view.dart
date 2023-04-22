import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixSessionView extends StatelessWidget {
  const MatrixSessionView(
      {this.displayName,
      required this.deviceId,
      this.lastSeenIp,
      this.lastSeenTimestamp,
      super.key,
      this.verified = false,
      this.isThisDevice = false,
      this.beginVerification,
      this.removeSession});

  final String? displayName;
  final String deviceId;
  final String? lastSeenIp;
  final int? lastSeenTimestamp;
  final bool verified;
  final bool isThisDevice;
  final Function? beginVerification;
  final Function? removeSession;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          color: Theme.of(context).extension<ExtraColors>()!.surfaceLow1, borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                  child: Icon(
                    getIcon(),
                    color: verified ? Colors.green : Colors.redAccent,
                  ),
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (displayName != null) tiamat.Text.labelEmphasised(displayName!),
                          if (displayName != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: SizedBox(
                                width: 10,
                                child: tiamat.Seperator(
                                  padding: 0,
                                ),
                              ),
                            ),
                          tiamat.Text.labelLow(deviceId),
                          if (isThisDevice)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: SizedBox(
                                width: 10,
                                child: tiamat.Seperator(
                                  padding: 0,
                                ),
                              ),
                            ),
                          if (isThisDevice)
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5), color: Theme.of(context).colorScheme.primary),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: tiamat.Text.tiny("This Device"),
                              ),
                            )
                        ],
                      ),
                      Row(
                        children: [
                          if (lastSeenTimestamp != null)
                            tiamat.Text.tiny(
                                "Last Seen: ${DateFormat(DateFormat.YEAR_MONTH_WEEKDAY_DAY).format(DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp!))}"),
                          if (lastSeenIp != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: SizedBox(
                                width: 10,
                                child: tiamat.Seperator(
                                  padding: 0,
                                ),
                              ),
                            ),
                          if (lastSeenIp != null) tiamat.Text.tiny(lastSeenIp!),
                        ],
                      )
                    ]),
              ],
            ),
            Row(
              children: [
                if (verified == false)
                  tiamat.Button.secondary(
                    text: "Verify",
                    onTap: () => beginVerification?.call(),
                  ),
                if (!isThisDevice)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                    child: tiamat.IconButton(
                      icon: Icons.delete,
                      size: 24,
                      onPressed: () => removeSession?.call(),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData getIcon() {
    if (displayName == null) return Icons.device_unknown;

    if (["ios", "android", "mobile"].any((element) => displayName!.toLowerCase().contains(element))) {
      return Icons.smartphone;
    }

    if ([
      "desktop",
      "linux",
      "windows",
      "mac",
    ].any((element) => displayName!.toLowerCase().contains(element))) {
      return Icons.desktop_windows_rounded;
    }

    if (displayName!.toLowerCase().contains("web")) {
      return Icons.web;
    }

    return Icons.device_unknown;
  }
}
