import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';

abstract class ReadReceiptComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  Stream<String> get onReadReceiptsUpdated;

  List<String>? getReceipts(TimelineEvent event);
}
