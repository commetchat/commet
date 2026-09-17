import 'dart:async';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class _ScreenAudio implements VoipStream {
  @override
  double volume;

  _ScreenAudio(this.volume);

  final StreamController<void> _changed = StreamController.broadcast();

  @override
  Stream<void> get onStreamChanged => _changed.stream;

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    _changed.add(null);
  }

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
  testWidgets('follows a volume changed from another control', (tester) async {
    final stream = _ScreenAudio(0.6);
    await pumpControl(tester, stream);

    // What the context menu slider does while the overlay is on screen.
    await stream.setVolume(0.3);
    await tester.pump();

    expect(find.text('30%'), findsOneWidget);
    expect(find.byIcon(Icons.volume_down_rounded), findsOneWidget);
  });

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
