import 'dart:async';
import 'package:commet/cache/cache_file_provider.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/text_utils.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimeline extends Timeline {
  matrix.Timeline? _matrixTimeline;
  late matrix.Room _matrixRoom;

  MatrixTimeline(
    Client client,
    Room room,
    matrix.Room matrixRoom,
  ) {
    events = List.empty(growable: true);
    _matrixRoom = matrixRoom;
    this.client = client;

    initTimeline();
  }

  void initTimeline() async {
    _matrixTimeline = await _matrixRoom.getTimeline(
      onInsert: (index) {
        if (_matrixTimeline == null) return;
        insertEvent(index, convertEvent(_matrixTimeline!.events[index]));
      },
      onChange: (index) {
        if (_matrixTimeline == null) return;
        events[index] = convertEvent(_matrixTimeline!.events[index],
            existing: events[index]);
        notifyChanged(index);
      },
      onRemove: (index) {
        events.removeAt(index);
        onRemove.add(index);
      },
    );

    // This could maybe make load times realllly slow if we have a ton of stuff in the cache?
    // Might be better to only convert as many as we would need to display immediately and then convert the rest on demand
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var converted = convertEvent(_matrixTimeline!.events[i]);
      insertEvent(i, converted);
    }
  }

  TimelineEvent convertEvent(matrix.Event event, {TimelineEvent? existing}) {
    TimelineEvent? e;
    if (existing != null) {
      e = existing;
    } else {
      e = TimelineEvent();
    }

    e.eventId = event.eventId;
    e.originServerTs = event.originServerTs;
    e.source = event.toJson().toString();

    if (client.peerExists(event.senderId)) {
      e.sender = client.getPeer(event.senderId)!;
    }

    e.body = event.getDisplayEvent(_matrixTimeline!).body;

    switch (event.type) {
      case matrix.EventTypes.Message:
        e = parseMessage(e, event);
        break;
      case matrix.EventTypes.Redaction:
        e.type = EventType.redaction;
    }

    switch (event.status) {
      case matrix.EventStatus.removed:
        e.status = TimelineEventStatus.removed;
        break;
      case matrix.EventStatus.error:
        e.status = TimelineEventStatus.error;
        break;
      case matrix.EventStatus.sending:
        e.status = TimelineEventStatus.sending;
        break;
      case matrix.EventStatus.sent:
        e.status = TimelineEventStatus.sent;
        break;
      case matrix.EventStatus.synced:
        e.status = TimelineEventStatus.synced;
        break;
      case matrix.EventStatus.roomState:
        e.status = TimelineEventStatus.roomState;
        break;
    }

    if (event.redacted) {
      e.status = TimelineEventStatus.removed;
    }

    return e;
  }

  TimelineEvent parseMessage(TimelineEvent e, matrix.Event matrixEvent) {
    e.type = EventType.message;

    parseAnyAttachments(matrixEvent, e);

    handleFormatting(matrixEvent, e);

    return e;
  }

  void handleFormatting(matrix.Event matrixEvent, TimelineEvent e) {
    var format = matrixEvent.content.tryGet<String>("format");

    if (format != null) {
      e.bodyFormat = format;
      e.formattedBody = matrixEvent.formattedText;

      if (format == "org.matrix.custom.html") {
        e.formattedContent = MatrixHtmlParser.parse(e.formattedBody!);
      }
    } else {
      e.bodyFormat = "chat.commet.default";

      e.formattedContent = TextUtils.manageRtlSpan(matrixEvent.body,
          TextUtils.formatString(matrixEvent.body, allowBigEmoji: true));
    }
  }

  void parseAnyAttachments(matrix.Event matrixEvent, TimelineEvent e) {
    if (matrixEvent.hasAttachment) {
      double? width;
      double? height;
      var info = matrixEvent.content.tryGet<Map<String, dynamic>>("info");
      if (info != null) {
        int? w = info.tryGet("w");
        int? h = info.tryGet("h");

        if (w != null) width = w.toDouble();
        if (h != null) height = h.toDouble();
      }

      Attachment file = Attachment(
          fileProvider: CacheFileProvider(
              matrixEvent.attachmentMxcUrl.toString(), () async {
            var file = await matrixEvent.downloadAndDecryptAttachment();
            return file.bytes;
          }),
          name: matrixEvent.content.tryGet<String>("filename") ??
              matrixEvent.body,
          mimeType: matrixEvent.attachmentMimetype,
          height: height,
          width: width,
          thumbnail: matrixEvent.thumbnailMxcUrl != null
              ? CacheFileProvider.thumbnail(
                  matrixEvent.attachmentMxcUrl.toString(), () async {
                  var file = await matrixEvent.downloadAndDecryptAttachment(
                      getThumbnail: true);
                  return file.bytes;
                })
              : null);

      e.body = null;
      e.attachments = List.from([file]);
    }
  }

  @override
  Future<void> loadMoreHistory() async {
    if (_matrixTimeline!.canRequestHistory) {
      return await _matrixTimeline!.requestHistory();
    }
  }

  @override
  void deleteEventByIndex(int index) async {
    var event = _matrixTimeline!.events[index];
    var status = event.status;

    if (status == matrix.EventStatus.sent ||
        status == matrix.EventStatus.synced && event.canRedact) {
      events[index].status = TimelineEventStatus.removed;
      await _matrixRoom.redactEvent(event.eventId);
    } else {
      events.removeAt(index);
      _matrixTimeline!.events[index].remove();
      onRemove.add(index);
    }
  }

  @override
  void markAsRead(TimelineEvent event) async {
    if (event.sender == client.user) return;

    if (event.status == TimelineEventStatus.synced) {
      _matrixTimeline?.setReadMarker(event.eventId);
    }
  }

  @override
  Iterable<Peer>? get receipts => getReceipts();

  Iterable<Peer>? getReceipts() {
    var mxReceipts = _matrixTimeline?.events.first.receipts;
    var mapped = mxReceipts?.map((receipt) => client.getPeer(receipt.user.id)!);
    if (mapped == null) return null;

    var list = mapped.toList(growable: true);
    var sender = client.getPeer(_matrixTimeline!.events.first.senderId);
    if (sender != null) list.add(sender);

    return list;
  }
}
