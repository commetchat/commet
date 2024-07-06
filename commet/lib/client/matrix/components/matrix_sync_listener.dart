import 'package:matrix/matrix.dart' as matrix;

abstract class MatrixRoomSyncListener {
  onSync(matrix.JoinedRoomUpdate update);
}
