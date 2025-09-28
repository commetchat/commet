import 'dart:convert';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart' as lk;

class MatrixLivekitBackend {
  MatrixRoom room;
  lk.Room? livekitRoom;
  MatrixLivekitBackend(this.room);

  Future<VoipSession?> join() async {
    var wellKnown = await room.matrixRoom.client.getWellknown();
    final foci = wellKnown.additionalProperties["org.matrix.msc4143.rtc_foci"]
        as List<dynamic>?;

    if (foci == null) {
      return null;
    }

    Uri? fociUrl;
    for (var focus in foci) {
      Log.d("Focus: ${focus}");
      final data = focus as Map<String, dynamic>;
      if (data["type"] != "livekit") {
        continue;
      }

      final url = data["livekit_service_url"] as String;
      fociUrl = Uri.parse(url);
      break;
    }

    if (fociUrl == null) {
      Log.e("Failed to find a valid LiveKit Foci");
      return null;
    }

    Log.d("Got Foci Url: ${fociUrl}");

    final token = await room.matrixRoom.client
        .requestOpenIdToken(room.matrixRoom.client.userID!, {});

    Log.d("Received token from homeserver: ${token}");
    var uri = Uri.https(fociUrl.host, "/sfu/get");

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

    Log.d("Got sfu: ${data}");
    final sfuUrl = data["url"];
    final jwt = data["jwt"];

    final roomOptions = lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    );

    final lkRoom = lk.Room(roomOptions: roomOptions);
    await lkRoom.prepareConnection(sfuUrl, jwt);
    await lkRoom.connect(sfuUrl, jwt);

    await lkRoom.localParticipant?.setMicrophoneEnabled(true);

    livekitRoom = lkRoom;
    return MatrixLivekitVoipSession(room, lkRoom);
  }
}
