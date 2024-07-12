import 'dart:convert';

import 'package:commet/client/matrix/components/push_notifications/matrix_push_notification_component.dart';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/atoms/panel.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixNotifierComponentView extends StatefulWidget {
  const MatrixNotifierComponentView(this.component, {super.key});
  final MatrixPushNotificationComponent component;

  @override
  State<MatrixNotifierComponentView> createState() =>
      _MatrixNotifierComponentViewState();
}

class _MatrixNotifierComponentViewState
    extends State<MatrixNotifierComponentView> {
  List<matrix.Pusher>? pushers;

  @override
  void initState() {
    widget.component.client.getMatrixClient().getPushers().then((value) {
      setState(() {
        pushers = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (pushers == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final ourPushers = pushers!.where((e) =>
        e.deviceDisplayName ==
        widget.component.client.getMatrixClient().clientName);

    final otherPushers = pushers!.where((e) =>
        e.deviceDisplayName !=
        widget.component.client.getMatrixClient().clientName);

    return Column(children: [
      Panel(
        header: "This Device",
        mode: TileType.surfaceContainerLowest,
        child: Column(
            children: ourPushers
                .map((e) => Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: buildPusher(e)))
                .toList()),
      ),
      const SizedBox(
        height: 10,
      ),
      Panel(
        header: "Other Devices",
        mode: TileType.surfaceContainerLowest,
        child: Column(
            children: otherPushers
                .map((e) => Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      child: buildPusher(e),
                    ))
                .toList()),
      ),
    ]);
  }

  Widget buildPusher(matrix.Pusher pusher) {
    String keyDisplay = "${pusher.pushkey.substring(0, 10)}...";

    try {
      var uri = Uri.parse(pusher.pushkey);
      if (uri.scheme == "http" || uri.scheme == "https") {
        var redacted = Uri(
            host: uri.host,
            port: uri.port,
            scheme: uri.scheme,
            path: "${uri.path.substring(0, 6)}...");

        keyDisplay = Uri.decodeFull(redacted.toString());
      }
    } catch (_) {}

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tiamat.Text.label(pusher.appDisplayName),
              tiamat.Text.labelLow(pusher.appId),
              tiamat.Text.labelLow("key: $keyDisplay"),
              tiamat.Text.labelLow("device: ${pusher.deviceDisplayName}",
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              tiamat.Text.labelLow(
                  "data: ${const JsonEncoder.withIndent("  ").convert(pusher.data.toJson())}"),
              tiamat.Text.labelLow("kind: ${pusher.kind}"),
            ],
          ),
        ),
      ),
    );
  }
}
