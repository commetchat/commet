import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/photo_album_room/photo.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_message.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/utils/mime.dart';
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
    for (var i = 0; i < _timeline.events.length; i++) {
      handleNewEvent(_timeline.events[i], i);
    }

    _timeline.onEventAdded.stream.listen(onEventAdded);
    _timeline.onChange.stream.listen(onEventChanged);
    _timeline.onRemove.stream.listen(onEventRemoved);
  }

  void handleNewEvent(TimelineEvent event, int index) {
    print("Photo timeline handling event: $event");
    if (event is! MatrixTimelineEventMessage) return;
    if (event.event.attachmentMimetype == "") return;

    if (!(Mime.imageTypes.contains(event.event.attachmentMimetype) ||
        Mime.videoTypes.contains(event.event.attachmentMimetype))) {
      return;
    }

    if (index != 0) {
      index = _photos.length;
    }

    var photo = eventToPhoto(event);
    if (photo != null) {
      _photos.insert(index, photo);
    }
  }

  MatrixPhoto? eventToPhoto(TimelineEventMessage event) {
    var photo = MatrixPhoto(event as MatrixTimelineEvent);
    return photo;
  }

  @override
  List<Photo> get photos => _photos;

  void onEventAdded(int event) {
    handleNewEvent(_timeline.events[event], event);
  }

  @override
  bool get canLoadMorePhotos => _timeline.canLoadHistory;

  @override
  Future<void> loadMorePhotos() async {
    await _timeline.loadMoreHistory();
  }

  void onEventChanged(int index) {
    print("On Event Changed!");
    var event = _timeline.events[index];

    if (event is! MatrixTimelineEventMessage) return;

    var newIndex = _photos.indexWhere((photo) {
      var p = photo as MatrixPhoto;
      return (p.event.eventId == event.eventId ||
          p.event.event.transactionId == event.event.transactionId);
    });

    if (newIndex == -1) {
      print("Tried to update an event which does not currently exist!!");
    }

    var newPhoto = eventToPhoto(event);
    if (newPhoto != null) {
      _photos[newIndex] = newPhoto;
    } else {
      _photos.removeAt(newIndex);
    }
  }

  void onEventRemoved(int index) {
    var event = _timeline.events[index];

    _photos
        .removeWhere((e) => (e as MatrixPhoto).event.eventId == event.eventId);
  }
}
