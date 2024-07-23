import 'package:commet/client/attachment.dart';
import 'package:commet/client/matrix/components/threads/matrix_thread_timeline.dart';
import 'package:commet/client/matrix/extensions/matrix_event_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_mixin_reactions.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_mixin_related.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventMessage extends MatrixTimelineEvent
    with MatrixTimelineEventRelated, MatrixTimelineEventReactions
    implements TimelineEventMessage {
  MatrixTimelineEventMessage(super.event, {required super.client}) {
    attachments = _parseAnyAttachments();
    links = _findLinks();
  }

  matrix.Client get mx => client.getMatrixClient();

  @override
  late List<Uri>? links;

  @override
  late List<Attachment>? attachments;

  @override
  bool get editable => true;

  @override
  String? get body => event.plaintextBody;

  @override
  String get plainTextBody => event.plaintextBody;

  String _getPlaintextBody({Timeline? timeline}) {
    var e = getDisplayEvent(timeline);

    if (["m.file", "m.image", "m.video"].contains(e.messageType)) {
      var file = e.content["file"] is Map<String, dynamic>
          ? e.content['file'] as Map<String, dynamic>
          : null;
      if (e.content.containsKey("url") == false &&
          (file?.containsKey("url") != true)) {
        return e.plaintextBody;
      }

      if (e.content.containsKey("filename")) {
        if (e.content["filename"] == e.plaintextBody) {
          return "";
        }

        return e.plaintextBody;
      } else {
        return "";
      }
    }

    return e.plaintextBody;
  }

  String _getFormattedBody({Timeline? timeline}) {
    var e = getDisplayEvent(timeline);

    if (["m.file", "m.image", "m.video"].contains(e.messageType)) {
      return e.formattedText;
    }

    if (e.formattedText == "") {
      return e.plaintextBody;
    }

    return e.formattedText;
  }

  @override
  Widget? buildFormattedContent({Timeline? timeline}) {
    var displayEvent = getDisplayEvent(timeline);
    bool isFormatted = displayEvent.content.tryGet<String>("format") != null;
    if (isFormatted) {
      return MatrixHtmlParser.parse(_getFormattedBody(timeline: timeline), mx);
    } else {
      var plain = _getPlaintextBody(timeline: timeline);
      if (plain != "") {
        return MatrixHtmlParser.parse(plain, mx);
      }
    }

    return null;
  }

  @override
  bool isEdited(Timeline timeline) {
    var e = event.getDisplayEvent(getTimeline(timeline)!);
    return e.eventId != event.eventId;
  }

  List<Attachment>? _parseAnyAttachments() {
    String filename = event.content.containsKey("filename")
        ? event.content["filename"] as String
        : event.body;

    if (event.hasAttachment) {
      double? width = event.attachmentWidth;
      double? height = event.attachmentHeight;

      Attachment? attachment;

      if (Mime.imageTypes.contains(event.attachmentMimetype)) {
        attachment = ImageAttachment(
            MatrixMxcImage(event.attachmentMxcUrl!, mx,
                blurhash: event.attachmentBlurhash,
                doThumbnail: true,
                matrixEvent: event),
            MxcFileProvider(mx, event.attachmentMxcUrl!, event: event),
            width: width,
            name: filename,
            height: height);
      } else if (Mime.videoTypes.contains(event.attachmentMimetype)) {
        // Only load videos if the event has finished sending, otherwise
        // matrix dart sdk gives us the video file when we ask for thumbnail
        if (event.status.isSending == false) {
          attachment = VideoAttachment(
              MxcFileProvider(mx, event.attachmentMxcUrl!, event: event),
              thumbnail: event.videoThumbnailUrl != null
                  ? MatrixMxcImage(event.videoThumbnailUrl!, mx,
                      blurhash: event.attachmentBlurhash,
                      doFullres: false,
                      autoLoadFullRes: false,
                      doThumbnail: true,
                      matrixEvent: event)
                  : null,
              name: filename,
              width: width,
              fileSize: event.infoMap['size'] as int?,
              height: height);
        }
      } else {
        attachment = FileAttachment(
            MxcFileProvider(mx, event.attachmentMxcUrl!, event: event),
            name: filename,
            mimeType: event.attachmentMimetype,
            fileSize: event.infoMap['size'] as int?);
      }

      return List.from([attachment]);
    }

    return null;
  }

  List<Uri>? _findLinks() {
    var text = _getFormattedBody();
    var start = text.indexOf("<mx-reply>");
    var end = text.indexOf("</mx-reply>");

    if (start != -1 && end != -1 && start < end) {
      text = text.replaceRange(start, end, "");
    }

    var foundLinks = TextUtils.findUrls(text);

    foundLinks?.removeWhere((element) => element.authority == "matrix.to");
    if (foundLinks?.isEmpty == true) {
      foundLinks = null;
    }

    return foundLinks;
  }

  matrix.Event getDisplayEvent(Timeline? tl) {
    var mx = getTimeline(tl);

    if (mx == null) return event;

    return event.getDisplayEvent(mx);
  }

  matrix.Timeline? getTimeline(Timeline? tl) {
    if (tl == null) return null;

    if (tl is MatrixThreadTimeline) {
      return tl.mainRoomTimeline.matrixTimeline;
    } else {
      return (tl as MatrixTimeline).matrixTimeline;
    }
  }
}
