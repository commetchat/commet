import 'dart:async';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/matrix/extensions/matrix_event_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/mime.dart';
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
    this.room = room;

    initTimeline();
  }

  void initTimeline() async {
    _matrixTimeline = await _matrixRoom.getTimeline(
      onInsert: onEventInserted,
      onChange: onEventChanged,
      onRemove: onEventRemoved,
    );

    // This could maybe make load times realllly slow if we have a ton of stuff in the cache?
    // Might be better to only convert as many as we would need to display immediately and then convert the rest on demand
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var converted = convertEvent(_matrixTimeline!.events[i]);
      insertEvent(i, converted);
    }
  }

  void onEventInserted(index) {
    if (_matrixTimeline == null) return;
    insertNewEvent(index, convertEvent(_matrixTimeline!.events[index]));
  }

  void onEventChanged(index) {
    if (_matrixTimeline == null) return;
    events[index] =
        convertEvent(_matrixTimeline!.events[index], existing: events[index]);
    notifyChanged(index);
  }

  void onEventRemoved(index) {
    events.removeAt(index);
    onRemove.add(index);
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

    var displayEvent = event.getDisplayEvent(_matrixTimeline!);
    e.edited = displayEvent.eventId != event.eventId;

    if (event.relationshipType == "m.replace") {
      e.type = EventType.edit;
      return e;
    }

    e.body = displayEvent.body;

    switch (event.type) {
      case matrix.EventTypes.Message:
        e = parseMessage(e, displayEvent);
        break;
      case matrix.EventTypes.Redaction:
        e.type = EventType.redaction;
    }

    switch (displayEvent.status) {
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

    if (displayEvent.redacted) {
      e.status = TimelineEventStatus.removed;
    }

    return e;
  }

  TimelineEvent parseMessage(TimelineEvent e, matrix.Event matrixEvent) {
    e.type = EventType.message;

    handleFormatting(matrixEvent, e);
    parseAnyAttachments(matrixEvent, e);

    // if the message body is the same as a file name we dont want to display that
    if (e.attachments != null &&
        e.attachments!.any((element) => matrixEvent.body == element.name)) {
      e.body = null;
      e.formattedBody = null;
      e.formattedContent = null;
      e.bodyFormat = null;
    }

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
      double? width = matrixEvent.attachmentWidth;
      double? height = matrixEvent.attachmentHeight;

      Attachment? attachment;

      if (Mime.imageTypes.contains(matrixEvent.attachmentMimetype)) {
        attachment = ImageAttachment(
            MatrixMxcImage(matrixEvent.attachmentMxcUrl!, _matrixRoom.client,
                blurhash: matrixEvent.attachmentBlurhash,
                doThumbnail: false,
                matrixEvent: matrixEvent),
            width: width,
            name: matrixEvent.body,
            height: height);
      }

      if (Mime.videoTypes.contains(matrixEvent.attachmentMimetype)) {
        attachment = VideoAttachment(
            MxcFileProvider(_matrixRoom.client, matrixEvent.attachmentMxcUrl!,
                event: matrixEvent),
            thumbnail: MatrixMxcImage(
                matrixEvent.videoThumbnailUrl!, _matrixRoom.client,
                blurhash: matrixEvent.attachmentBlurhash,
                matrixEvent: matrixEvent),
            name: matrixEvent.body,
            width: width,
            height: height);
      }

      if (attachment != null) {
        e.attachments = List.from([attachment]);
      }
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
    print("Marking as read: ${event.eventId}");
    if (event.sender == client.user) return;

    if (event.type == EventType.edit ||
        event.status == TimelineEventStatus.synced) {
      _matrixTimeline?.setReadMarker();
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
