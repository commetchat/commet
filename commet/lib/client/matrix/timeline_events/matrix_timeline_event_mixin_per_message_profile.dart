import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/timeline_events/matrix_per_message_profile.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_per_message_profile.dart';
import 'package:matrix/matrix.dart' as matrix;

mixin MatrixTimelineEventPerMessageProfile on MatrixTimelineEvent
    implements TimelineEventFeaturePerMessageProfile {
  String? _cachedFor;
  MatrixPerMessageProfileData? _cachedData;
  PerMessageProfile? _cachedProfile;

  matrix.Event getPerMessageProfileSource({Timeline? timeline}) => event;

  @override
  PerMessageProfile? getPerMessageProfile({Timeline? timeline}) {
    _updateCache(timeline: timeline);
    return _cachedProfile;
  }

  MatrixPerMessageProfileData? getPerMessageProfileData({Timeline? timeline}) {
    _updateCache(timeline: timeline);
    return _cachedData;
  }

  void _updateCache({Timeline? timeline}) {
    var source = getPerMessageProfileSource(timeline: timeline);

    if (_cachedFor == source.eventId) {
      return;
    }

    _cachedFor = source.eventId;
    _cachedData = MatrixPerMessageProfileData.fromEventContent(source.content);
    _cachedProfile = _cachedData != null ? _buildProfile(_cachedData!) : null;
  }

  PerMessageProfile _buildProfile(MatrixPerMessageProfileData data) {
    var avatarUrl =
        data.avatarUrl != null ? Uri.tryParse(data.avatarUrl!) : null;

    return PerMessageProfile(
        id: data.id,
        displayName: data.displayName,
        avatar: avatarUrl != null
            ? MatrixMxcImage(avatarUrl, client.getMatrixClient(),
                doThumbnail: true,
                autoLoadFullRes: false,
                doFullres: false,
                thumbnailHeight: 86)
            : null,
        clearAvatar: data.clearAvatar,
        hasFallback: data.hasFallback,
        pronouns: data.pronouns,
        color: MatrixMember.hashColor("$senderId${data.id}"));
  }

  String stripFallback(String body, {Timeline? timeline}) {
    var data = getPerMessageProfileData(timeline: timeline);

    if (data == null || !data.hasFallback || data.displayName == null) {
      return body;
    }

    return stripPerMessageProfileFallback(body, data.displayName!);
  }

  String stripFallbackHtml(String html, {Timeline? timeline}) {
    var data = getPerMessageProfileData(timeline: timeline);

    if (data == null || !data.hasFallback || data.displayName == null) {
      return html;
    }

    return stripPerMessageProfileFallbackHtml(html);
  }
}
