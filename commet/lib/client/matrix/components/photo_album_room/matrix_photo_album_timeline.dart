import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/utils/notifying_list.dart';

class MatrixPhotoAlbumTimeline implements PhotoAlbumTimeline {
  final MatrixRoom room;
  late Timeline _timeline;

  NotifyingList<Photo> _photos = NotifyingList.empty(growable: true);

  MatrixPhotoAlbumTimeline(this.room);

  @override
  Stream<int> get onAdded => _photos.onAdd;

  @override
  Stream<int> get onChanged => _photos.onItemUpdated;

  @override
  Stream<int> get onRemoved => _photos.onRemove;

  Future<void> initTimeline() async {
    _timeline = await room.getTimeline();
    for (var event in _timeline.events) {
      handleEvent(event);
    }

    _timeline.onEventAdded.stream.listen(onEventAdded);
  }

  void handleEvent(TimelineEvent event) {
    if (event is! TimelineEventMessage) return;

    if (event.attachments?.isEmpty != false) {
      return;
    }

    for (var attachment in event.attachments!) {
      if (attachment is ImageAttachment) {
        _photos.add(
            MatrixPhoto(event as MatrixTimelineEvent, attachment: attachment));
      }

      if (attachment is VideoAttachment) {
        _photos.add(
            MatrixPhoto(event as MatrixTimelineEvent, attachment: attachment));
      }
    }
  }

  @override
  List<Photo> get photos => _photos;

  void onEventAdded(int event) {
    handleEvent(_timeline.events[event]);
  }

  @override
  bool get canLoadMorePhotos => _timeline.canLoadHistory;

  @override
  Future<void> loadMorePhotos() async {
    await _timeline.loadMoreHistory();
  }
}
