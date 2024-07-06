import 'dart:convert';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/extensions/matrix_event_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEvent implements TimelineEvent {
  late matrix.Event event;
  matrix.Event? displayEvent;

  @override
  List<Attachment>? attachments;

  @override
  String? body;

  @override
  String? bodyFormat;

  @override
  bool get editable => type == EventType.message;

  @override
  bool get edited =>
      displayEvent != null ? displayEvent!.eventId != event.eventId : false;

  @override
  String get eventId => event.eventId;

  @override
  String? formattedBody;

  @override
  Widget? formattedContent;

  @override
  DateTime get originServerTs => event.originServerTs;

  @override
  Map<Emoticon, Set<String>>? reactions;

  @override
  String? get relatedEventId => getRelatedEventId();

  @override
  EventRelationshipType? relationshipType;

  @override
  String get senderId => event.senderId;

  @override
  String? get source => event.toJson().toString();

  @override
  String? get stateKey => event.stateKey;

  @override
  late TimelineEventStatus status;

  @override
  late EventType type;

  @override
  List<Uri>? links;

  MatrixTimelineEvent(matrix.Event event, matrix.Client client,
      {matrix.Timeline? timeline}) {
    convertEvent(event, client, timeline: timeline);
  }

  convertEvent(matrix.Event event, matrix.Client client,
      {matrix.Timeline? timeline}) {
    this.event = event;
    body = event.plaintextBody;

    try {
      if (event.relationshipType != null) {
        handleRelationshipType();
      }

      displayEvent = timeline != null ? event.getDisplayEvent(timeline) : null;

      type = convertType(event) ?? EventType.invalid;

      switch (event.type) {
        case matrix.EventTypes.Message:
          parseMessage(displayEvent ?? event, client,
              timeline: timeline, originalEvent: event);
          break;
        case matrix.EventTypes.Sticker:
          if (timeline != null) parseSticker(event, client, timeline: timeline);
          break;
      }

      status = convertStatus(event.status);

      if (displayEvent?.redacted == true) {
        status = TimelineEventStatus.removed;
      }
    } catch (error) {
      type = EventType.unknown;

      if (kDebugMode) {
        rethrow;
      }
    }
  }

  void handleRelationshipType() {
    switch (event.relationshipType) {
      case "m.in_reply_to":
        relationshipType = EventRelationshipType.reply;
        break;
      case "m.thread":
        if (getThreadRichResponseId() != null) {
          relationshipType = EventRelationshipType.reply;
        }
    }
  }

  String? getThreadRichResponseId() {
    var rel = event.content["m.relates_to"] as Map<String, dynamic>?;
    if (rel == null) {
      return null;
    }

    var reponse = rel["m.in_reply_to"] as Map<String, dynamic>?;

    if (reponse == null) {
      return null;
    }

    if (rel["is_falling_back"] == true) {
      return null;
    }

    return reponse["event_id"];
  }

  String? getRelatedEventId() {
    if (event.relationshipType == "m.thread") {
      return getThreadRichResponseId();
    }

    return event.relationshipEventId;
  }

  EventType? convertType(matrix.Event event) {
    const dict = {
      matrix.EventTypes.Message: EventType.message,
      matrix.EventTypes.Reaction: EventType.redaction,
      matrix.EventTypes.Sticker: EventType.sticker,
      matrix.EventTypes.RoomCreate: EventType.roomCreated,
      matrix.EventTypes.Encrypted: EventType.encrypted,
    };

    var result = dict[event.type];

    if (event.type == matrix.EventTypes.Message) {
      if (event.messageType == "m.emote") {
        result = EventType.emote;
      }

      if (event.content["chat.commet.type"] == "chat.commet.sticker") {
        result = EventType.sticker;
      }
    }

    if (event.type == matrix.EventTypes.RoomMember &&
        event.content['membership'] != null) {
      result = convertMembershipEvent(event);
    }

    if (event.relationshipType == "m.replace") {
      result = EventType.edit;
    }

    return result;
  }

  TimelineEventStatus convertStatus(matrix.EventStatus status) {
    const dict = {
      matrix.EventStatus.error: TimelineEventStatus.error,
      matrix.EventStatus.sending: TimelineEventStatus.sending,
      matrix.EventStatus.sent: TimelineEventStatus.sent,
      matrix.EventStatus.synced: TimelineEventStatus.synced,
      matrix.EventStatus.roomState: TimelineEventStatus.roomState,
    };

    return dict[status]!;
  }

  EventType convertMembershipEvent(matrix.Event event) {
    var prevMembership = event.prevContent?['membership'];
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
        if (prevMembership == "invite") {
          return EventType.memberInvitationRejected;
        }
        return EventType.memberLeft;
      case "invite":
        return EventType.memberInvited;
    }

    return EventType.unknown;
  }

  void parseMessage(matrix.Event displayEvent, matrix.Client client,
      {matrix.Timeline? timeline, required matrix.Event originalEvent}) {
    handleFormatting(displayEvent, client);

    parseAnyAttachments(displayEvent, client);
    if (timeline != null) {
      handleReactions(originalEvent, timeline);
    }

    // if the message body is the same as a file name we dont want to display that
    if (attachments != null &&
        attachments!.any((element) => displayEvent.body == element.name)) {
      body = null;
      formattedBody = null;
      formattedContent = null;
      bodyFormat = null;
    }
  }

  void parseSticker(matrix.Event e, matrix.Client client,
      {matrix.Timeline? timeline}) {
    parseAnyAttachments(e, client);

    if (timeline != null) {
      handleReactions(e, timeline);
    }
  }

  void handleFormatting(matrix.Event matrixEvent, matrix.Client client) {
    var format = matrixEvent.content.tryGet<String>("format");
    body = matrixEvent.plaintextBody;

    if (format != null) {
      bodyFormat = format;
      formattedBody = matrixEvent.formattedText;
    } else {
      bodyFormat = "chat.commet.default";
      formattedBody = body!;
    }

    var text = formattedBody!;
    var start = text.indexOf("<mx-reply>");
    var end = text.indexOf("</mx-reply>");

    if (start != -1 && end != -1 && start < end) {
      text = text.replaceRange(start, end, "");
    }

    links = TextUtils.findUrls(text);

    links?.removeWhere((element) => element.authority == "matrix.to");
    if (links?.isEmpty == true) {
      links = null;
    }

    formattedContent =
        Container(key: GlobalKey(), child: buildFormattedContent());
  }

  @override
  Widget? buildFormattedContent() {
    if (formattedBody == null) {
      return null;
    }

    return MatrixHtmlParser.parse(formattedBody!, event.room.client);
  }

  void parseAnyAttachments(matrix.Event matrixEvent, matrix.Client client) {
    if (matrixEvent.status.isSending) return;

    if (matrixEvent.hasAttachment) {
      double? width = matrixEvent.attachmentWidth;
      double? height = matrixEvent.attachmentHeight;

      Attachment? attachment;

      if (Mime.imageTypes.contains(matrixEvent.attachmentMimetype)) {
        attachment = ImageAttachment(
            MatrixMxcImage(matrixEvent.attachmentMxcUrl!, client,
                blurhash: matrixEvent.attachmentBlurhash,
                doThumbnail: true,
                matrixEvent: matrixEvent),
            MxcFileProvider(client, matrixEvent.attachmentMxcUrl!,
                event: matrixEvent),
            width: width,
            name: matrixEvent.body,
            height: height);
      } else if (Mime.videoTypes.contains(matrixEvent.attachmentMimetype)) {
        // Only load videos if the event has finished sending, otherwise
        // matrix dart sdk gives us the video file when we ask for thumbnail
        if (matrixEvent.status.isSending == false) {
          attachment = VideoAttachment(
              MxcFileProvider(client, matrixEvent.attachmentMxcUrl!,
                  event: matrixEvent),
              thumbnail: matrixEvent.videoThumbnailUrl != null
                  ? MatrixMxcImage(matrixEvent.videoThumbnailUrl!, client,
                      blurhash: matrixEvent.attachmentBlurhash,
                      doFullres: false,
                      autoLoadFullRes: false,
                      doThumbnail: true,
                      matrixEvent: matrixEvent)
                  : null,
              name: matrixEvent.body,
              width: width,
              fileSize: matrixEvent.infoMap['size'] as int?,
              height: height);
        }
      } else {
        attachment = FileAttachment(
            MxcFileProvider(client, matrixEvent.attachmentMxcUrl!,
                event: matrixEvent),
            name: matrixEvent.body,
            mimeType: matrixEvent.attachmentMimetype,
            fileSize: matrixEvent.infoMap['size'] as int?);
      }

      attachments = List.from([attachment]);
    }
  }

  void handleReactions(matrix.Event matrixEvent, matrix.Timeline timeline) {
    if (!matrixEvent.hasAggregatedEvents(
        timeline, matrix.RelationshipTypes.reaction)) return;

    reactions = {};

    var events = matrixEvent
        .aggregatedEvents(timeline, matrix.RelationshipTypes.reaction)
        .toList();

    events.sort((eventA, eventB) =>
        eventA.originServerTs.compareTo(eventB.originServerTs));

    for (var event in events) {
      var emoji = getEmoticonFromReactionEvent(event, timeline);
      if (!reactions!.containsKey(emoji)) reactions![emoji] = {};

      if (reactions!.containsKey(emoji)) {
        reactions![emoji]!.add(event.senderId);
      }
    }
  }

  Emoticon getEmoticonFromReactionEvent(
      matrix.Event event, matrix.Timeline timeline) {
    var content = event.content["m.relates_to"] as Map<String, Object?>;
    var key = content['key'] as String;

    if (key.startsWith("mxc://")) {
      return MatrixEmoticon(Uri.parse(key), timeline.room.client,
          shortcode: event.content.tryGet("shortcode") ?? "");
    }

    return UnicodeEmoticon(key, shortcode: content['shortcode'] as String?);
  }

  @override
  bool get highlight => false;

  @override
  String get rawContent => const JsonEncoder.withIndent("  ")
      .convert(const JsonDecoder().convert(jsonEncode(event.toJson())));

  @override
  bool operator ==(Object other) {
    if (other is! MatrixTimelineEvent) return false;

    return eventId == other.eventId;
  }

  @override
  int get hashCode => eventId.hashCode;
}
