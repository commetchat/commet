import 'dart:async';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/extensions/matrix_event_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/foundation.dart';

import '../client.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'matrix_client.dart';

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
    await (client as MatrixClient).firstSync;

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
    if (index < _matrixTimeline!.events.length) {
      events[index] =
          convertEvent(_matrixTimeline!.events[index], existing: events[index]);
      notifyChanged(index);
    }
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

    try {
      e.eventId = event.eventId;
      e.originServerTs = event.originServerTs;
      e.source = event.toJson().toString();
      e.senderId = event.senderId;

      if (event.relationshipType != null) {
        switch (event.relationshipType) {
          case "m.in_reply_to":
            e.relatedEventId = event.relationshipEventId;
            e.relationshipType = EventRelationshipType.reply;
            break;
        }
      }

      var displayEvent = event.getDisplayEvent(_matrixTimeline!);

      e.relatedEventId = event.relationshipEventId;
      e.edited = displayEvent.eventId != event.eventId;
      e.body = displayEvent.body;

      e.type = convertType(event) ?? EventType.invalid;

      switch (event.type) {
        case matrix.EventTypes.Message:
          e = parseMessage(e, displayEvent);
          break;
        case matrix.EventTypes.Sticker:
          parseSticker(e, event);
          break;
      }

      e.status = convertStatus(event.status);

      if (displayEvent.redacted) {
        e.status = TimelineEventStatus.removed;
      }

      return e;
    } catch (error) {
      var result = TimelineEvent();
      result.type = EventType.unknown;

      if (kDebugMode) {
        rethrow;
      }

      return result;
    }
  }

  EventType? convertType(matrix.Event event) {
    const dict = {
      matrix.EventTypes.Message: EventType.message,
      matrix.EventTypes.Reaction: EventType.redaction,
      matrix.EventTypes.Sticker: EventType.sticker,
      matrix.EventTypes.RoomCreate: EventType.roomCreated,
    };

    var result = dict[event.type];

    if (event.type == matrix.EventTypes.RoomMember &&
        event.content['membership'] != null) {
      result = convertMembershipEvent(event);
    }

    if (event.relationshipType == "m.replace") {
      result = EventType.edit;
    }

    return result;
  }

  EventType convertMembershipEvent(matrix.Event event) {
    switch (event.content['membership'] as String) {
      case "join":
        if (event.prevContent != null) {
          if (event.prevContent!['avatar_url'] != null &&
              event.content['avatar_url'] != null &&
              event.prevContent!['avatar_url'] != event.content['avatar_url'])
            return EventType.memberAvatar;

          if (event.prevContent!['displayname'] != null &&
              event.content['displayname'] != null &&
              event.prevContent!['displayname'] != event.content['displayname'])
            return EventType.memberDisplayName;
        }

        return EventType.memberJoined;

      case "leave":
        return EventType.memberLeft;
    }

    return EventType.unknown;
  }

  TimelineEventStatus convertStatus(matrix.EventStatus status) {
    const dict = {
      matrix.EventStatus.removed: TimelineEventStatus.removed,
      matrix.EventStatus.error: TimelineEventStatus.error,
      matrix.EventStatus.sending: TimelineEventStatus.sending,
      matrix.EventStatus.sent: TimelineEventStatus.sent,
      matrix.EventStatus.synced: TimelineEventStatus.synced,
      matrix.EventStatus.roomState: TimelineEventStatus.roomState,
    };

    return dict[status]!;
  }

  TimelineEvent parseMessage(TimelineEvent e, matrix.Event matrixEvent) {
    handleFormatting(matrixEvent, e);
    parseAnyAttachments(matrixEvent, e);
    handleReactions(matrixEvent, e);

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

    e.body = matrixEvent.plaintextBody;

    if (format != null) {
      e.bodyFormat = format;
      e.formattedBody = matrixEvent.formattedText;

      if (format == "org.matrix.custom.html") {
        e.formattedContent =
            MatrixHtmlParser.parse(e.formattedBody!, _matrixRoom.client);
      }
    } else {
      e.bodyFormat = "chat.commet.default";

      e.formattedContent = TextUtils.manageRtlSpan(matrixEvent.body,
          TextUtils.formatString(matrixEvent.body, allowBigEmoji: true));
    }
  }

  void handleReactions(matrix.Event matrixEvent, TimelineEvent e) {
    if (!matrixEvent.hasAggregatedEvents(
        _matrixTimeline!, matrix.RelationshipTypes.reaction)) return;

    e.reactions = {};

    var events = matrixEvent
        .aggregatedEvents(_matrixTimeline!, matrix.RelationshipTypes.reaction)
        .toList();

    events.sort((eventA, eventB) =>
        eventA.originServerTs.compareTo(eventB.originServerTs));

    for (var event in events) {
      var emoji = getEmojiFromEvent(event);
      if (!e.reactions!.containsKey(emoji)) e.reactions![emoji] = {};

      if (e.reactions!.containsKey(emoji)) {
        e.reactions![emoji]!.add(event.senderId);
      }
    }
  }

  Emoticon getEmojiFromEvent(matrix.Event event) {
    var content = event.content["m.relates_to"] as Map<String, Object?>;
    var key = content['key'] as String;

    if (key.startsWith("mxc://")) {
      return MatrixEmoticon(Uri.parse(key), _matrixRoom.client,
          shortcode: event.content.tryGet("shortcode") ?? "");
    }

    return UnicodeEmoticon(key, shortcode: content['shortcode'] as String?);
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
      } else if (Mime.videoTypes.contains(matrixEvent.attachmentMimetype)) {
        attachment = VideoAttachment(
            MxcFileProvider(_matrixRoom.client, matrixEvent.attachmentMxcUrl!,
                event: matrixEvent),
            thumbnail: matrixEvent.videoThumbnailUrl != null
                ? MatrixMxcImage(
                    matrixEvent.videoThumbnailUrl!, _matrixRoom.client,
                    blurhash: matrixEvent.attachmentBlurhash,
                    doFullres: false,
                    doThumbnail: true,
                    matrixEvent: matrixEvent)
                : null,
            name: matrixEvent.body,
            width: width,
            fileSize: matrixEvent.infoMap['size'] as int?,
            height: height);
      } else {
        attachment = FileAttachment(
            MxcFileProvider(_matrixRoom.client, matrixEvent.attachmentMxcUrl!,
                event: matrixEvent),
            name: matrixEvent.body,
            mimeType: matrixEvent.attachmentMimetype,
            fileSize: matrixEvent.infoMap['size'] as int?);
      }

      e.attachments = List.from([attachment]);
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
    if (event.senderId == client.user!.identifier) return;

    if (event.type == EventType.edit ||
        event.status == TimelineEventStatus.synced) {
      _matrixTimeline?.setReadMarker();
    }
  }

  @override
  List<String>? get receipts => getReceipts();

  List<String>? getReceipts() {
    if (_matrixTimeline == null) return null;
    var state = _matrixTimeline!.room.receiptState;
    if (state.mainThread == null) return null;

    const displayableTypes = [
      matrix.EventTypes.Message,
      matrix.EventTypes.Sticker,
    ];

    Set<String> ids = {};
    matrix.Event? latestDisplayableEvent;
    for (int i = 0; i < _matrixTimeline!.events.length; i++) {
      var event = _matrixTimeline!.events[i];
      ids.add(event.eventId);

      if (displayableTypes.contains(event.type)) {
        latestDisplayableEvent = event;
        break;
      }
    }

    var receipts = state.mainThread!.otherUsers.entries
        .where((element) => ids.contains(element.value.eventId))
        .map((entry) => entry.key)
        .toList(growable: true);

    if (latestDisplayableEvent != null &&
        latestDisplayableEvent.senderId != client.user!.identifier)
      receipts.add(latestDisplayableEvent.senderId);

    return receipts;
  }

  @override
  Future<TimelineEvent?> fetchEventByIdInternal(String eventId) async {
    var event = await _matrixRoom.getEventById(eventId);
    if (event == null) return null;
    return convertEvent(event);
  }

  void parseSticker(TimelineEvent e, matrix.Event event) {
    parseAnyAttachments(event, e);
    handleReactions(event, e);
  }

  Future<void> removeReaction(
      TimelineEvent reactingTo, Emoticon reaction) async {
    var event = await _matrixRoom.getEventById(reactingTo.eventId);
    if (event == null) return;

    if (!event.hasAggregatedEvents(
        _matrixTimeline!, matrix.RelationshipTypes.reaction)) return;

    var events = event
        .aggregatedEvents(_matrixTimeline!, matrix.RelationshipTypes.reaction)
        .where((element) => element.senderId == _matrixRoom.client.userID);

    for (var e in events) {
      if (!e.content.containsKey("m.relates_to")) continue;
      var content = e.content["m.relates_to"] as Map<String, Object?>;

      if (content.containsKey("key") && content["key"] == reaction.key) {
        await _matrixRoom.redactEvent(e.eventId);
        return;
      }
    }
  }
}
