import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/molecules/call_session_live_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class FakeVoipStream implements VoipStream {
  FakeVoipStream({required this.direction, required this.type});

  @override
  final VoipStreamDirection direction;
  @override
  final VoipStreamType type;

  /// Legacy 1:1 streams initialise their renderer asynchronously and report
  /// it through [onStreamChanged]; until then there is nothing to draw.
  bool rendererReady = true;
  final StreamController<void> _streamChanged =
      StreamController.broadcast(sync: true);

  @override
  Stream<void> get onStreamChanged => _streamChanged.stream;

  void finishInitRenderer() {
    rendererReady = true;
    _streamChanged.add(null);
  }

  @override
  String get streamId => 'fake-${type.name}';

  @override
  Widget? buildVideoRenderer(BoxFit fit, Key key) => rendererReady
      ? Container(key: ValueKey('preview-${type.name}'))
      : const CircularProgressIndicator();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVoipSession implements VoipSession {
  final List<VoipStream> _streams = [];
  // Synchronous so a publish/unpublish is visible on the very next pump.
  final StreamController<void> _stateChanged =
      StreamController.broadcast(sync: true);

  int stopScreenshareCalls = 0;
  int stopCameraCalls = 0;

  @override
  List<VoipStream> get streams => _streams;

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  @override
  bool get isSharingScreen => _streams.any((s) =>
      s.direction == VoipStreamDirection.outgoing &&
      s.type == VoipStreamType.screenshare);

  @override
  bool get isCameraEnabled => _streams.any((s) =>
      s.direction == VoipStreamDirection.outgoing &&
      s.type == VoipStreamType.video);

  FakeVoipStream publish(VoipStreamType type,
      {VoipStreamDirection direction = VoipStreamDirection.outgoing,
      bool rendererReady = true}) {
    final stream = FakeVoipStream(direction: direction, type: type)
      ..rendererReady = rendererReady;
    _streams.add(stream);
    _stateChanged.add(null);
    return stream;
  }

  void unpublish(VoipStreamType type) {
    _streams.removeWhere(
        (s) => s.direction == VoipStreamDirection.outgoing && s.type == type);
    _stateChanged.add(null);
  }

  @override
  Future<void> stopScreenshare() async {
    stopScreenshareCalls++;
    unpublish(VoipStreamType.screenshare);
  }

  @override
  Future<void> stopCamera() async {
    stopCameraCalls++;
    unpublish(VoipStreamType.video);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _testApp(Widget child, {double width = 240}) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(extensions: const [ThemeSettings()]),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows nothing while not sharing', (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));

    expect(find.text('LIVE'), findsNothing);
    expect(find.byKey(const ValueKey('preview-screenshare')), findsNothing);
  });

  testWidgets('starting a screen share shows the LIVE pill and a preview',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));

    session.publish(VoipStreamType.screenshare);
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-screenshare')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-video')), findsNothing);
  });

  testWidgets('the pill says what is live', (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));

    session.publish(VoipStreamType.screenshare);
    await tester.pump();
    expect(find.text('Screen'), findsOneWidget);

    session.publish(VoipStreamType.video);
    await tester.pump();
    expect(find.text('Screen + Camera'), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-screenshare')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-video')), findsOneWidget);

    session.unpublish(VoipStreamType.screenshare);
    await tester.pump();
    expect(find.text('Camera'), findsOneWidget);
  });

  testWidgets('stop buttons stop the matching share and stay in sync',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));
    session.publish(VoipStreamType.screenshare);
    session.publish(VoipStreamType.video);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('live-stop-screenshare')));
    await tester.pump();
    expect(session.stopScreenshareCalls, 1);
    expect(session.stopCameraCalls, 0);
    expect(find.byKey(const ValueKey('preview-screenshare')), findsNothing);
    expect(find.byKey(const ValueKey('preview-video')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('live-stop-video')));
    await tester.pump();
    expect(session.stopCameraCalls, 1);
    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('capture ended by the OS (no button) hides the live section',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));
    session.publish(VoipStreamType.screenshare);
    await tester.pump();
    expect(find.text('LIVE'), findsOneWidget);

    session.unpublish(VoipStreamType.screenshare);
    await tester.pump();

    expect(find.text('LIVE'), findsNothing);
    expect(find.byKey(const ValueKey('preview-screenshare')), findsNothing);
    expect(session.stopScreenshareCalls, 0);
    expect(tester.getSize(find.byType(CallSessionLivePanel)).height, 0);
  });

  testWidgets('tapping the preview opens the voice channel', (tester) async {
    final session = FakeVoipSession();
    var opened = 0;
    await tester.pumpWidget(_testApp(
        CallSessionLivePanel(session: session, onOpenRoom: () => opened++)));
    session.publish(VoipStreamType.video);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('preview-video')));
    await tester.pump();
    expect(opened, 1);

    // The stop button must not also open the room.
    await tester.tap(find.byKey(const ValueKey('live-stop-video')));
    await tester.pump();
    expect(opened, 1);
    expect(session.stopCameraCalls, 1);
  });

  testWidgets('incoming video from other users is not previewed',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));
    session.publish(VoipStreamType.video,
        direction: VoipStreamDirection.incoming);
    session.publish(VoipStreamType.screenshare,
        direction: VoipStreamDirection.incoming);
    await tester.pump();

    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('screen and camera previews sit side by side to stay compact',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));
    session.publish(VoipStreamType.screenshare);
    session.publish(VoipStreamType.video);
    await tester.pump();

    final screen =
        tester.getRect(find.byKey(const ValueKey('preview-screenshare')));
    final camera = tester.getRect(find.byKey(const ValueKey('preview-video')));
    expect(screen.top, camera.top);
    expect(screen.right, lessThanOrEqualTo(camera.left));
    // Both previews together fit inside the panel width.
    expect(tester.getSize(find.byType(CallSessionLivePanel)).width, 240);
  });

  testWidgets('preview appears once a late renderer becomes ready',
      (tester) async {
    final session = FakeVoipSession();
    await tester.pumpWidget(_testApp(CallSessionLivePanel(session: session)));
    final stream = session.publish(VoipStreamType.video, rendererReady: false);
    await tester.pump();
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-video')), findsNothing);

    // Only the stream reports this; the session state does not change.
    stream.finishInitRenderer();
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-video')), findsOneWidget);
  });
}
