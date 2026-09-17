import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class _ScreenAudio implements VoipStream {
  @override
  double volume;

  _ScreenAudio(this.volume);

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpControl(WidgetTester tester, VoipStream stream) {
  return tester.pumpWidget(MaterialApp(
    theme: ThemeData.light().copyWith(extensions: const [ThemeSettings()]),
    home: Scaffold(body: Center(child: StreamVolumeControl(stream))),
  ));
}

void main() {
  testWidgets('shows the screen share volume', (tester) async {
    await pumpControl(tester, _ScreenAudio(0.6));

    expect(find.text('60%'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0.6);
  });

  testWidgets('mute sets the volume to 0 and unmute brings it back',
      (tester) async {
    final stream = _ScreenAudio(0.6);
    await pumpControl(tester, stream);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(stream.volume, 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_off_rounded));
    await tester.pump();
    expect(stream.volume, 0.6);
  });

  testWidgets('unmuting a volume saved as 0 goes to 100%', (tester) async {
    final stream = _ScreenAudio(0);
    await pumpControl(tester, stream);

    await tester.tap(find.byIcon(Icons.volume_off_rounded));
    await tester.pump();
    expect(stream.volume, 1.0);
  });

  testWidgets('dragging the slider changes the volume', (tester) async {
    final stream = _ScreenAudio(1.0);
    await pumpControl(tester, stream);

    await tester.drag(find.byType(Slider), const Offset(-200, 0));
    await tester.pump();
    expect(stream.volume, 0);
  });
}
