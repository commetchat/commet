import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:commet/utils/mime.dart';
import 'package:matrix/src/event.dart';

class MatrixEventSearchSession extends EventSearchSession {
  MatrixTimeline timeline;
  String? currentSearchTerm;
  String? prevBatch;

  MatrixEventSearchSession(this.timeline);

  @override
  bool currentlySearching = false;

  bool _requireUrl = false;
  bool _requireImage = false;
  bool _requireVideo = false;
  bool _requireAttachment = false;
  String? _requiredType;
  String? _requiredSender;

  static const String hasLinkString = 'has:link';
  static const String hasImageString = 'has:image';
  static const String hasVideoString = 'has:video';
  static const String hasFileString = 'has:file';

  List<String>? _words;

  @override
  Stream<List<TimelineEvent<Client>>> startSearch(String searchTerm) async* {
    currentSearchTerm = searchTerm.toLowerCase();

    currentlySearching = true;
    _words = currentSearchTerm!.split(' ');

    var typeMatch = _words!.where((w) => w.startsWith("type:")).firstOrNull;

    if (typeMatch != null) {
      _requiredType = typeMatch.split('type:').last;
    }

    var userMatch = _words!.where((w) => w.startsWith("from:")).firstOrNull;
    if (userMatch != null) {
      _requiredSender = userMatch.split('from:').last;
    }

    if (_words!.contains(hasLinkString)) _requireUrl = true;
    if (_words!.contains(hasImageString)) _requireImage = true;
    if (_words!.contains(hasVideoString)) _requireVideo = true;
    if (_words!.contains(hasFileString)) _requireAttachment = true;

    _words = _words!
        .where((w) =>
            [
              typeMatch,
              hasLinkString,
              hasImageString,
              hasVideoString,
              hasFileString
            ].contains(w) ==
            false)
        .toList();

    var search = timeline.matrixTimeline!
        .startSearch(searchTerm: searchTerm, searchFunc: searchFunc);
    List<TimelineEvent<Client>> result = List.empty();
    await for (final chunk in search) {
      result = chunk.$1
          .map((e) => (timeline.room as MatrixRoom).convertEvent(e))
          .toList();

      Map<String, TimelineEvent> m = {};

      for (var event in result) {
        var type = TimelineViewEntryState.eventToDisplayType(event);
        if (type != TimelineEventWidgetDisplayType.hidden) {
          m[event.eventId] = event;
        }
      }

      if (chunk.$2 != null) {
        prevBatch = chunk.$2;
      }

      result = m.values.toList();
      result.sort((a, b) => b.originServerTs.compareTo(a.originServerTs));

      yield result;
    }

    currentlySearching = false;
    yield result;
  }

  bool searchFunc(Event event) {
    final numMatchingWords =
        _words!.where((w) => event.plaintextBody.contains(w)).length;

    if (_requireAttachment) {
      if (event.hasAttachment == false) {
        return false;
      }
    }

    if (_requireImage) {
      if (!Mime.imageTypes.contains(event.attachmentMimetype)) {
        return false;
      }
    }

    if (_requireVideo) {
      if (!Mime.videoTypes.contains(event.attachmentMimetype)) {
        return false;
      }
    }

    if (_requireUrl) {
      if (!(event.plaintextBody.contains("https://") ||
          event.plaintextBody.contains("http://"))) {
        return false;
      }
    }

    if (_requiredType != null) {
      if (event.type != _requiredType && event.messageType != _requiredType) {
        return false;
      }
    }

    if (_requiredSender != null) {
      if (event.senderId != _requiredSender) {
        return false;
      }
    }

    if (numMatchingWords < (_words!.length.toDouble() / 2.0)) {
      return false;
    }

    return true;
  }
}

class MatrixEventSearchComponent implements EventSearchComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixEventSearchComponent(this.client);

  @override
  Future<EventSearchSession> createSearchSession(Room room) async {
    var timeline = await room.getTimeline();
    return MatrixEventSearchSession(timeline as MatrixTimeline);
  }
}
