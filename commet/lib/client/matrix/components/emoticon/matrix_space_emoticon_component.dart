import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixSpaceEmoticonComponent extends MatrixEmoticonComponent
    implements SpaceEmoticonComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixSpace space;

  MatrixSpaceEmoticonComponent(
    super.client,
    this.space,
  );

  @override
  Map<String, dynamic> getState(String packKey) {
    var states = getAllStates();
    var data = states[packKey];

    return data;
  }

  @override
  Map<String, dynamic> getAllStates() {
    if (!space.matrixRoom.states
        .containsKey(MatrixEmoticonComponent.roomEmotesStateKey)) return {};

    var state =
        (space.matrixRoom.states[MatrixEmoticonComponent.roomEmotesStateKey]
            as Map<String, matrix.Event>);

    var result = <String, dynamic>{};

    for (var key in state.keys) {
      result[key] = state[key]!.content;
    }

    return result;
  }

  @override
  Future<void> setState(String packKey, Map<String, dynamic> content) async {
    var event = await space.matrixRoom.client.setRoomStateWithKey(
        space.matrixRoom.id,
        MatrixEmoticonComponent.roomEmotesStateKey,
        packKey,
        content);

    var result = await space.matrixRoom.getEventById(event);
    space.matrixRoom
        .states[MatrixEmoticonComponent.roomEmotesStateKey]![packKey] = result!;
  }
}
