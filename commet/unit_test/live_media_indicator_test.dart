import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/ui/atoms/live_media_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

Widget _testApp(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [ThemeSettings()]),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  Future<void> pumpIndicator(WidgetTester tester, Set<LiveMedia> media) =>
      tester.pumpWidget(_testApp(LiveMediaIndicator(media)));

  testWidgets('a member sharing their screen gets a LIVE pill', (tester) async {
    await pumpIndicator(tester, {LiveMedia.screen});

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_rounded), findsNothing);
  });

  testWidgets('a member with only their camera on gets a camera icon',
      (tester) async {
    await pumpIndicator(tester, {LiveMedia.camera});

    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('screen and camera together show the LIVE pill', (tester) async {
    await pumpIndicator(tester, {LiveMedia.screen, LiveMedia.camera});

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_rounded), findsNothing);
  });

  testWidgets('a member publishing nothing shows nothing', (tester) async {
    await pumpIndicator(tester, const {});

    expect(find.text('LIVE'), findsNothing);
    expect(find.byIcon(Icons.videocam_rounded), findsNothing);
  });
}
