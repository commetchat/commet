// The screen share picker: screens and windows on their own tabs, a
// selection confirmed with Share (or a double click), the system audio
// switch, and sources that come and go while it is open.
import 'dart:async';
import 'dart:typed_data';

import 'package:commet/ui/organisms/call_view/screen_capture_source_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// A 1x1 transparent PNG, so the cards have a thumbnail to draw.
final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _Source extends DesktopCapturerSource {
  _Source(this.id, this.name, this.type);

  @override
  final String id;
  @override
  final String name;
  @override
  final SourceType type;
  @override
  Uint8List? get thumbnail => _png;
  @override
  ThumbnailSize get thumbnailSize => ThumbnailSize(480, 270);
}

class _Feed implements ScreenSourceFeed {
  final addedCtl = StreamController<DesktopCapturerSource>.broadcast();
  final removedCtl = StreamController<DesktopCapturerSource>.broadcast();
  final changedCtl = StreamController<DesktopCapturerSource>.broadcast();
  int refreshes = 0;

  @override
  Stream<DesktopCapturerSource> get added => addedCtl.stream;
  @override
  Stream<DesktopCapturerSource> get removed => removedCtl.stream;
  @override
  Stream<DesktopCapturerSource> get changed => changedCtl.stream;
  @override
  Future<void> refresh() async => refreshes++;
}

final screen1 = _Source('screen:1', 'Screen 1', SourceType.Screen);
final screen2 = _Source('screen:2', 'Screen 2', SourceType.Screen);
final browser = _Source('window:10', 'Roscord - Browser', SourceType.Window);
final editor = _Source('window:11', 'main.dart - Editor', SourceType.Window);
final game = _Source('window:12', 'Some Game', SourceType.Window);

void main() {
  late _Feed feed;
  ScreenCaptureDialogResult? result;
  late bool closed;

  setUp(() {
    feed = _Feed();
    result = null;
    closed = false;
  });

  Future<void> open(WidgetTester tester, List<DesktopCapturerSource> sources,
      {Duration refreshEvery = const Duration(seconds: 2)}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showDialog<ScreenCaptureDialogResult>(
                context: context,
                builder: (_) => Dialog(
                    child: ScreenCaptureSourceDialog(sources, feed,
                        refreshEvery: refreshEvery)),
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder shareButton() => find.byKey(const ValueKey('screen-share-go'));
  bool shareEnabled(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(shareButton()).onPressed != null;

  testWidgets('screens and windows are on tabs of their own', (tester) async {
    await open(tester, [browser, screen1, editor, screen2, game]);

    expect(find.text('Screens (2)'), findsOneWidget);
    expect(find.text('Windows (3)'), findsOneWidget);
    expect(find.text('Screen 1'), findsOneWidget);
    expect(find.text('Roscord - Browser'), findsNothing);

    await tester.tap(find.text('Windows (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Roscord - Browser'), findsOneWidget);
    expect(find.text('Some Game'), findsOneWidget);
    expect(find.text('Screen 1'), findsNothing);
  });

  testWidgets('a single screen is ready to share at once', (tester) async {
    await open(tester, [screen1, browser]);
    expect(shareEnabled(tester), isTrue);

    await tester.tap(shareButton());
    await tester.pumpAndSettle();
    expect(result?.source.id, 'screen:1');
    expect(result?.captureAudio, isTrue);
  });

  testWidgets('with several screens, nothing is shared until one is picked',
      (tester) async {
    await open(tester, [screen1, screen2]);
    expect(shareEnabled(tester), isFalse);

    await tester.tap(find.text('Screen 2'));
    await tester.pump();
    expect(shareEnabled(tester), isTrue);
    await tester.tap(shareButton());
    await tester.pumpAndSettle();
    expect(result?.source.id, 'screen:2');
  });

  testWidgets('a window is picked from its tab, without the system audio',
      (tester) async {
    await open(tester, [screen1, browser, editor]);

    await tester.tap(find.text('Windows (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('main.dart - Editor'));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(shareButton());
    await tester.pumpAndSettle();

    expect(result?.source.id, 'window:11');
    expect(result?.captureAudio, isFalse);
  });

  testWidgets('a double click shares straight away', (tester) async {
    await open(tester, [screen1, screen2]);

    await tester.tap(find.text('Screen 2'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Screen 2').first);
    await tester.pumpAndSettle();
    expect(result?.source.id, 'screen:2');
  });

  testWidgets('Cancel shares nothing', (tester) async {
    await open(tester, [screen1]);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('windows opened or closed meanwhile come and go', (tester) async {
    await open(tester, [screen1, browser, editor]);
    await tester.tap(find.text('Windows (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('main.dart - Editor'));
    await tester.pump();

    feed.addedCtl.add(game);
    await tester.pump();
    expect(find.text('Windows (3)'), findsOneWidget);
    expect(find.text('Some Game'), findsOneWidget);

    // The picked window closes: nothing is picked any more.
    feed.removedCtl.add(editor);
    await tester.pump();
    expect(find.text('Windows (2)'), findsOneWidget);
    expect(find.text('main.dart - Editor'), findsNothing);
    expect(shareEnabled(tester), isFalse);
  });

  testWidgets('thumbnails are refreshed while it is open, not after',
      (tester) async {
    await open(tester, [screen1],
        refreshEvery: const Duration(milliseconds: 500));
    final before = feed.refreshes;
    await tester.pump(const Duration(milliseconds: 1600));
    expect(feed.refreshes - before, 3);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final after = feed.refreshes;
    await tester.pump(const Duration(seconds: 2));
    expect(feed.refreshes, after);
  });

  testWidgets('only windows: their tab opens, and says when screens are none',
      (tester) async {
    await open(tester, [browser]);
    expect(find.text('Roscord - Browser'), findsWidgets);
    expect(shareEnabled(tester), isTrue);

    await tester.tap(find.text('Screens (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No screens to share'), findsOneWidget);
  });
}
