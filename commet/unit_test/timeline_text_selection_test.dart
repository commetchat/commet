import 'package:commet/ui/molecules/room_timeline_widget/timeline_selection_area.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

const _body = 'the quick brown fox jumps over the lazy dog';

/// A message rendered like the desktop timeline renders it: HTML body inside
/// the event's own context menu, whose Copy entry resolves its text the same
/// way TimelineEventMenu does.
class _Message extends StatelessWidget {
  const _Message();

  @override
  Widget build(BuildContext context) {
    final selection = TimelineTextSelection.maybeOf(context);
    return tiamat.ContextMenu(
      items: [
        tiamat.ContextMenuItem(
          text: 'Copy',
          onPressed: () => Clipboard.setData(
              ClipboardData(text: selection?.textToCopy(_body) ?? _body)),
        ),
      ],
      child: Html(data: '<p>$_body</p>'),
    );
  }
}

Widget _timeline() => MaterialApp(
      theme: ThemeData.light().copyWith(extensions: const [ThemeSettings()]),
      home: const Scaffold(
        body: TimelineSelectionArea(
          child: Center(child: SizedBox(width: 600, child: _Message())),
        ),
      ),
    );

Offset _offsetOf(WidgetTester tester, String text, int index) {
  final paragraph = tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .firstWhere((p) => p.text.toPlainText().contains(text));
  final start = paragraph.text.toPlainText().indexOf(text);
  final position = TextPosition(offset: start + index);
  final caret = paragraph.getOffsetForCaret(position, Rect.zero);
  final lineHeight = paragraph.getFullHeightForCaret(position);
  return paragraph.localToGlobal(caret + Offset(0, lineHeight / 2));
}

Future<void> _dragSelect(WidgetTester tester, String text) async {
  final gesture = await tester.startGesture(_offsetOf(tester, text, 0),
      kind: PointerDeviceKind.mouse);
  await tester.pump();
  await gesture.moveTo(_offsetOf(tester, text, text.length));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _copyFromMenu(WidgetTester tester, Offset at) async {
  await tester.tapAt(at,
      buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Copy'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboard;
  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  testWidgets('menu Copy with a selection copies only the selection',
      (tester) async {
    await tester.pumpWidget(_timeline());
    await _dragSelect(tester, 'brown fox');

    await _copyFromMenu(tester, _offsetOf(tester, 'brown fox', 2));

    expect(clipboard, 'brown fox');
  });

  testWidgets('menu Copy without a selection copies the whole message',
      (tester) async {
    await tester.pumpWidget(_timeline());

    await _copyFromMenu(tester, _offsetOf(tester, 'lazy', 1));

    expect(clipboard, _body);
  });

  testWidgets(
      'menu Copy after the selection is cleared copies the whole message',
      (tester) async {
    await tester.pumpWidget(_timeline());
    await _dragSelect(tester, 'brown fox');
    await tester.tapAt(_offsetOf(tester, 'lazy', 1),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    await _copyFromMenu(tester, _offsetOf(tester, 'lazy', 1));

    expect(clipboard, _body);
  });

  testWidgets('Ctrl+C with a selection copies only the selection',
      (tester) async {
    await tester.pumpWidget(_timeline());
    await _dragSelect(tester, 'brown fox');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(clipboard, 'brown fox');
  });
}
