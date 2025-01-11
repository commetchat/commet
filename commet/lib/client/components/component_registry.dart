import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/space_component.dart';
import 'package:commet/client/matrix/components/command_component/matrix_command_component.dart';
import 'package:commet/client/matrix/components/direct_messages/matrix_direct_messages_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_space_emoticon_component.dart';
import 'package:commet/client/matrix/components/event_search/matrix_event_search_component.dart';
import 'package:commet/client/matrix/components/gif/matrix_gif_component.dart';
import 'package:commet/client/matrix/components/invitation/matrix_invitation_component.dart';
import 'package:commet/client/matrix/components/pinned_messages/matrix_pinned_messages_component.dart';
import 'package:commet/client/matrix/components/push_notifications/matrix_push_notification_component.dart';
import 'package:commet/client/matrix/components/read_receipts/matrix_read_receipt_component.dart';
import 'package:commet/client/matrix/components/threads/matrix_threads_component.dart';
import 'package:commet/client/matrix/components/typing_indicators/matrix_typing_indicators_component.dart';
import 'package:commet/client/matrix/components/url_preview/matrix_url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_space.dart';

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
      MatrixThreadsComponent(client),
      MatrixDirectMessagesComponent(client),
      MatrixEventSearchComponent(client)
    ];
  }

  static List<RoomComponent<MatrixClient, MatrixRoom>> getMatrixRoomComponents(
      MatrixClient client, MatrixRoom room) {
    return [
      MatrixRoomEmoticonComponent(client, room),
      MatrixGifComponent(client, room),
      MatrixReadReceiptComponent(client, room),
      MatrixTypingIndicatorsComponent(client, room),
      MatrixPinnedMessagesComponent(client, room),
    ];
  }

  static List<SpaceComponent<MatrixClient, MatrixSpace>>
      getMatrixSpaceComponents(MatrixClient client, MatrixSpace space) {
    return [
      MatrixSpaceEmoticonComponent(client, space),
    ];
  }
}
