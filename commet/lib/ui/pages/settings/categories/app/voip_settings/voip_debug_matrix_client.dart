import 'dart:convert';

import 'package:commet/client/alert.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/molecules/alert_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as mx;

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class VoipDebugMatrixClient extends StatefulWidget {
  const VoipDebugMatrixClient(this.client, {super.key});
  final MatrixClient client;
  @override
  State<VoipDebugMatrixClient> createState() => _VoipDebugMatrixClientState();
}

class _VoipDebugMatrixClientState extends State<VoipDebugMatrixClient> {
  bool loading = true;
  bool homeserverHasTurnServer = false;
  mx.TurnServerCredentials? credentials;
  webrtc.RTCPeerConnection? connection;
  List<webrtc.RTCIceCandidate> foundCandidates = List.empty(growable: true);
  webrtc.RTCSessionDescription? description;
  webrtc.RTCIceGatheringState? gatheringState;
  Map<String, dynamic>? connectionConfiguration;

  @override
  void initState() {
    super.initState();

    load();
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      var turnServer = await widget.client.getMatrixClient().getTurnServer();
      setState(() {
        credentials = turnServer;
        loading = false;
        homeserverHasTurnServer = true;
      });
    } catch (_) {
      setState(() {
        loading = false;
        homeserverHasTurnServer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        if (homeserverHasTurnServer == false)
          AlertView(Alert(AlertType.warning,
              messageGetter: () =>
                  "Your homeserver (${widget.client.getMatrixClient().homeserver}) does not have a TURN server configured",
              titleGetter: () => "TURN Error")),
        tiamat.Panel(
          mode: tiamat.TileType.surfaceLow1,
          header: "TURN Server (Homeserver Configuration)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (credentials != null) showTurnServerCredentials(),
              testTurnServer(),
            ],
          ),
        )
      ],
    );
  }

  Widget testTurnServer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: tiamat.Button.secondary(
            text: "Test TURN Server",
            onTap: testTurn,
          ),
        ),
        if (connection != null) showTestConnectionInfo()
      ],
    );
  }

  Widget showTurnServerCredentials() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tiamat.Text.labelLow("username: ${credentials!.username}"),
        tiamat.Text.labelLow("password: ${"•" * credentials!.password.length}"),
        const tiamat.Seperator(),
        for (var item in credentials!.uris) tiamat.Text.labelLow(item)
      ],
    );
  }

  Widget showTestConnectionInfo() {
    return Column(
      children: [
        tiamat.Panel(
          mode: tiamat.TileType.surfaceLow2,
          header: "Connection Test",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (connectionConfiguration != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: tiamat.Panel(
                    mode: tiamat.TileType.surfaceLow3,
                    header: "Connecting with config:",
                    child: tiamat.Text.tiny(const JsonEncoder.withIndent('  ')
                        .convert(connectionConfiguration!)
                        .replaceAll(credentials?.password ?? "",
                            "•" * (credentials?.password.length ?? 0))),
                  ),
                ),
              if (foundCandidates.isNotEmpty)
                tiamat.Panel(
                  header: "Candidates",
                  mode: tiamat.TileType.surfaceLow3,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var candidate in foundCandidates)
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: tiamat.Text.label(
                                  candidate.candidate ?? "ERROR")),
                        if (gatheringState ==
                            webrtc.RTCIceGatheringState
                                .RTCIceGatheringStateGathering)
                          const Align(
                            alignment: Alignment.topCenter,
                            child: CircularProgressIndicator(),
                          )
                      ]),
                ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: tiamat.Panel(
                      header: "Offer",
                      mode: tiamat.TileType.surfaceLow3,
                      child: tiamat.Text.tiny(description!.sdp ?? "")),
                )
            ],
          ),
        )
      ],
    );
  }

  testTurn() async {
    foundCandidates = List.empty(growable: true);

    var servers = credentials == null
        ? []
        : [
            {
              'username': credentials!.username,
              'credential': credentials!.password,
              'urls': List.from(credentials!.uris)
            },
          ];

    var configuration = <String, dynamic>{
      'iceServers': servers,
      'sdpSemantics': 'unified-plan',
    };

    var component = widget.client.getComponent<MatrixVoipComponent>();
    configuration = component!.alterPeerConfiguration(configuration);

    setState(() {
      connectionConfiguration = configuration;
    });

    connection = await webrtc.createPeerConnection(configuration);

    var mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': false
      },
      'video': false,
    };

    connection!.onIceCandidate = onIceCandidate;
    connection!.onIceGatheringState = onIceGatheringState;

    var media =
        await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
    for (var track in media.getTracks()) {
      await connection!.addTrack(track, media);
    }

    var offer = await connection!.createOffer({});
    await connection!.setLocalDescription(offer);
  }

  onIceCandidate(webrtc.RTCIceCandidate candidate) {
    setState(() {
      foundCandidates.add(candidate);
    });
  }

  onIceGatheringState(webrtc.RTCIceGatheringState state) {
    setState(() {
      gatheringState = state;
    });
  }
}
