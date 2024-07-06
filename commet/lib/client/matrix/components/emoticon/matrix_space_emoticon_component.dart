import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';

class MatrixSpaceEmoticonComponent extends MatrixEmoticonComponent
    implements SpaceEmoticonComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixSpace space;

  @override
  bool get canCreatePack => space.permissions.canEditRoomEmoticons;

  @override
  String get ownerId => space.identifier;

  @override
  String get ownerDisplayName => space.displayName;

  MatrixSpaceEmoticonComponent(
    MatrixClient client,
    this.space,
  ) : super(client, MatrixEmoticonRoomStateManager(space.matrixRoom));

  @override
  bool isGloballyAvailable(String packId) {
    return space.matrixRoom.client
        .isEmoticonPackGloballyAvailable(space.matrixRoom.id, packId);
  }
}
