import 'package:commet/client/alert.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AlertView extends StatelessWidget {
  final Alert alert;
  const AlertView(this.alert, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          getIcon(),
          color: getColor(context),
        ),
      ),
      Flexible(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tiamat.Text.labelEmphasised(alert.title),
            tiamat.Text.labelLow(alert.message),
          ],
        ),
      )
    ]);
  }

  IconData getIcon() {
    switch (alert.type) {
      case AlertType.info:
        return Icons.info;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.critical:
        return Icons.dangerous;
    }
  }

  Color? getColor(BuildContext context) {
    switch (alert.type) {
      case AlertType.warning:
        return Colors.amber;
      case AlertType.critical:
        return Theme.of(context).colorScheme.error;
      default:
        return null;
    }
  }
}
