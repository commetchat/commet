import 'package:commet/client/client.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';

abstract class GifComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  Future<List<GifSearchResult>> search(String query);

  Future<TimelineEvent?> sendGif(GifSearchResult gif, TimelineEvent? inReplyTo);

  String get searchPlaceholder;
}
