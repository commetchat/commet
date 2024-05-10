import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';

class MatrixSpaceEmoticonComponent extends MatrixEmoticonComponent
    implements SpaceEmoticonComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixSpace space;

  @override
  bool get canCreatePack => space.permissions.canEditRoomEmoticons;

  MatrixSpaceEmoticonComponent(
    MatrixClient client,
    this.space,
  ) : super(client, MatrixEmoticonRoomStateManager(space.matrixRoom));
}
