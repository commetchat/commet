import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/matrix/components/command_component/matrix_command_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_space_emoticon_component.dart';
import 'package:commet/client/matrix/components/gif/matrix_gif_component.dart';
import 'package:commet/client/matrix/components/invitation/matrix_invitation_component.dart';
import 'package:commet/client/matrix/components/push_notifications/matrix_push_notification_component.dart';
import 'package:commet/client/matrix/components/url_preview/matrix_url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:commet/client/simulated/components/simulated_component.dart';
import 'package:commet/client/simulated/components/simulated_emoticon_component.dart';
import 'package:commet/client/simulated/simulated_client.dart';

class ComponentRegistry {
  static List<Component<MatrixClient>> getMatrixComponents(
      MatrixClient client) {
    return [
      MatrixEmoticonComponent(
          client, MatrixEmoticonPersonalStateManager(client)),
      MatrixPushNotificationComponent(client),
      MatrixCommandComponent(client),
      MatrixUrlPreviewComponent(client),
      MatrixInvitationComponent(client),
    ];
  }

  static List<RoomComponent<MatrixClient, MatrixRoom>> getMatrixRoomComponents(
      MatrixClient client, MatrixRoom room) {
    return [
      MatrixRoomEmoticonComponent(client, room),
      MatrixGifComponent(client, room)
    ];
  }

  static List<SpaceComponent<MatrixClient, MatrixSpace>>
      getMatrixSpaceComponents(MatrixClient client, MatrixSpace space) {
    return [
      MatrixSpaceEmoticonComponent(client, space),
    ];
  }

  static List<Component<SimulatedClient>> getSimulatedComponents(
      SimulatedClient client) {
    return [
      SimulatedComponent(client),
      SimulatedEmoticonComponent(client),
    ];
  }
}
