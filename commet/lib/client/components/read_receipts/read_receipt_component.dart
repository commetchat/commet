import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';

abstract class ReadReceiptComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  Stream<void> get onReadReceiptsUpdated;

  List<String> get receipts;
}
