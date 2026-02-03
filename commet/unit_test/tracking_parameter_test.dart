import 'package:commet/utils/link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  final pairs = [
    (
      "https://deezer.com/track/891177062?utm_source=deezer",
      "https://deezer.com/track/891177062"
    ),
    (
      "https://youtu.be/dQw4w9WgXcQ?si=VIB_lCxCeWJxCjS5",
      "https://youtu.be/dQw4w9WgXcQ",
    ),
    (
      "https://open.spotify.com/track/4PTG3Z6ehGkBFwjybzWkR8?si=R9xmSd-dTvCCQTlOCYbluw",
      "https://open.spotify.com/track/4PTG3Z6ehGkBFwjybzWkR8"
    ),
    (
      "https://example.com?utm_source=remove_this&important=83746",
      "https://example.com?important=83746",
    ),
    (
      "https://www.instagram.com/reel/xxxxxxxxxxx/?igsh=xxxxxxxxxxxxxxxxxx==",
      "https://www.instagram.com/reel/xxxxxxxxxxx/"
    ),
    (
      "https://x.com/airyz_/status/0000000000000000000?s=46&t=v1Vs9upYM9FGppwyLTA7cg",
      "https://x.com/airyz_/status/0000000000000000000"
    ),
  ];

  final unchangedUrls = [
    "https://youtu.be/dQw4w9WgXcQ",
  ];

  TestWidgetsFlutterBinding.ensureInitialized();

  test("Validate removed trackers", () async {
    for (var pair in pairs) {
      var uri = Uri.parse(pair.$1);
      var expected = Uri.parse(pair.$2);

      var clean = await LinkUtils.cleanTrackingParameters(uri);

      print("Before: $uri   after: $clean");
      expect(clean.toString(), expected.toString());
    }
  });

  test("Validate unchanged urls", () async {
    for (var url in unchangedUrls) {
      var uri = Uri.parse(url);

      var clean = await LinkUtils.cleanTrackingParameters(uri);

      expect(clean.toString(), url.toString());
    }
  });
}
