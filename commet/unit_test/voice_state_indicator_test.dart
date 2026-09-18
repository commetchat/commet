import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/ui/atoms/voice_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

Widget _testApp(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [ThemeSettings()]),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  Future<void> pumpIndicator(WidgetTester tester, Set<VoiceState> state) =>
      tester.pumpWidget(_testApp(VoiceStateIndicator(state)));

  testWidgets('a muted member gets a crossed-out microphone', (tester) async {
    await pumpIndicator(tester, {VoiceState.muted});

    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.headset_off_rounded), findsNothing);
  });

  testWidgets('a deafened member gets a crossed-out headset, not both',
      (tester) async {
    await pumpIndicator(tester, {VoiceState.muted, VoiceState.deafened});

    expect(find.byIcon(Icons.headset_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
  });

  testWidgets('a member who is neither shows nothing', (tester) async {
    await pumpIndicator(tester, const {});

    expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
    expect(find.byIcon(Icons.headset_off_rounded), findsNothing);
  });
}
