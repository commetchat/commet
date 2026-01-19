import 'dart:convert';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart';

class MatrixLivekitBackend {
  MatrixRoom room;
  lk.Room? livekitRoom;
  MatrixLivekitBackend(this.room);

  Future<List<Uri>> getFociUrl() async {
    final selectedFocus = findSelectedFocus();

    var wellKnown = await room.matrixRoom.client.getWellknown();
    final livekitJwtServiceUrl = wellKnown
        .additionalProperties["org.matrix.msc4143.rtc_foci"] as List<dynamic>?;

    if (livekitJwtServiceUrl == null) {
      return [
        if (selectedFocus != null) selectedFocus,
      ];
    }

    Uri? fociUrl;
    for (var focus in livekitJwtServiceUrl) {
      Log.d("Focus: ${focus}");
      final data = focus as Map<String, dynamic>;
      if (data["type"] != "livekit") {
        continue;
      }

      final url = data["livekit_service_url"] as String;
      fociUrl = Uri.parse(url);

      return [
        if (selectedFocus != null) selectedFocus,
        if (selectedFocus != fociUrl) fociUrl,
      ];
    }

    return [
      if (selectedFocus != null) selectedFocus,
    ];
  }

  Uri? findSelectedFocus() {
    final states =
        room.matrixRoom.states[MatrixVoipRoomComponent.callMemberStateEvent];
    if (states == null) {
      return null;
    }

    final values = states.values.map((event) => event as Event).toList();
    values.sort((a, b) => a.originServerTs.compareTo(b.originServerTs));

    for (var entry in values) {
      final focusActive =
          entry.content.tryGet<Map<String, dynamic>>("focus_active");

      if (focusActive == null) {
        continue;
      }

      if (focusActive['type'] != "livekit") {
        Log.e("Unknown focus type: ${focusActive['type']}");
        continue;
      }

      if (focusActive['focus_selection'] != "oldest_membership") {
        Log.e(
            "Unknown focus selection algorithm: ${focusActive['focus_selection']}");
        continue;
      }

      final fociPreferred =
          entry.content.tryGet<List<dynamic>>("foci_preferred");
      Log.e("Selecting focus");
      if (fociPreferred == null) {
        continue;
      }

      for (var item in fociPreferred) {
        final map = item as Map<String, dynamic>;
        if (map['type'] != "livekit") continue;
        if (map['livekit_alias'] != room.identifier) continue;
        return Uri.parse(map['livekit_service_url']);
      }
    }

    return null;
  }

  Future<VoipSession?> join() async {
    WebrtcDefaultDevices.selectOutputDevice();

    final fociUrl = await getFociUrl();

    if (fociUrl.isEmpty) {
      Log.e("Failed to find a valid LiveKit service");
      return null;
    }

    final selectedFocus = fociUrl.first;
    Log.d("Got Foci Url: ${fociUrl}");

    final token = await room.matrixRoom.client
        .requestOpenIdToken(room.matrixRoom.client.userID!, {});

    if (selectedFocus.scheme != "https") {
      Log.e("Selected focus jwt does not use https");
      return null;
    }

    Log.d("Received token from homeserver: ${token}");
    final uri = Uri.parse(selectedFocus.toString() + "/sfu/get");

    final body = {
      "device_id": room.matrixRoom.client.deviceID!,
      "room": room.matrixRoom.id,
      "openid_token": {
        "matrix_server_name": token.matrixServerName,
        "access_token": token.accessToken,
        "expires_in": token.expiresIn,
      }
    };

    var result = await http.post(uri, body: jsonEncode(body));
    if (result.statusCode != 200) {
      Log.e("Failed to get sfu!");
      return null;
    }

    var data = jsonDecode(result.body) as Map<String, dynamic>;

    final sfuUrl = data["url"];
    Log.d("Got sfu: ${sfuUrl}");
    final jwt = data["jwt"];

    final roomOptions = lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    );

    final lkRoom = lk.Room(roomOptions: roomOptions);
    await lkRoom.prepareConnection(sfuUrl, jwt);
    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    await room.matrixRoom.client.setRoomStateWithKey(room.matrixRoom.id,
        MatrixVoipRoomComponent.callMemberStateEvent, stateKey, {
      "application": "m.call",
      "call_id": "",
      "device_id": room.matrixRoom.client.deviceID!,
      "expires": 14400000,
      "foci_preferred": fociUrl
          .map((e) => {
                "type": "livekit",
                "livekit_alias": room.identifier,
                "livekit_service_url": e.toString()
              })
          .toList(),
      "focus_active": {
        "focus_selection": "oldest_membership",
        "type": "livekit"
      },
      "scope": "m.room"
    });

    await lkRoom.connect(sfuUrl, jwt);

    var device = await WebrtcDefaultDevices.getDefaultMicrophoneId();

    print("Using default device: ${device}");
    await lkRoom.localParticipant?.setMicrophoneEnabled(true,
        audioCaptureOptions: lk.AudioCaptureOptions(deviceId: device));

    livekitRoom = lkRoom;
    return MatrixLivekitVoipSession(room, lkRoom);
  }
}
