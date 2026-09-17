import 'package:commet/client/components/emoticon/dynamic_emoticon_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_overlay.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class _FakeTimelineEventMenu implements TimelineEventMenu {
  @override
  List<Emoticon> get recentReactions => [];

  @override
  TimelineEventMenuEntry? addReactionAction;

  @override
  List<TimelineEventMenuEntry> get primaryActions => [];

  @override
  List<TimelineEventMenuEntry> get secondaryActions => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Emoticon implements Emoticon {
  @override
  final String slug;
  @override
  final String key;
  @override
  final String? shortcode;
  @override
  ImageProvider? get image => null;

  _Emoticon(this.slug, {String? key, this.shortcode})
      : key = key ?? slug;

  @override
  EmoticonUsage get usage => EmoticonUsage.emoji;
  @override
  bool get isEmoji => true;
  @override
  bool get isSticker => false;
  @override
  Uri? get url => null;
}

Widget _testApp(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const [ThemeSettings()],
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets(
      'scrolling over primary menu forwards onScrolled when no secondary menu is open, '
      'but does NOT forward when balloon is open (issue #58)', (tester) async {
    final link = LayerLink();
    final overlayKey = GlobalKey<TimelineOverlayState>();
    int scrollCount = 0;

    final fakeMenu = _FakeTimelineEventMenu();
    fakeMenu.addReactionAction = TimelineEventMenuEntry(
      name: 'Add Reaction',
      icon: Icons.add_reaction,
      secondaryMenuBuilder: (context, dismiss) => Container(
        key: const ValueKey('reaction_balloon'),
        width: 200,
        height: 200,
        color: Colors.blue,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        Stack(
          children: [
            Positioned(
              left: 100,
              top: 200,
              child: CompositedTransformTarget(
                link: link,
                child: const SizedBox(width: 200, height: 40),
              ),
            ),
            TimelineOverlay(
              key: overlayKey,
              link: link,
              showMessageMenu: true,
              onScrolled: (event) {
                scrollCount++;
              },
            ),
          ],
        ),
      ),
    );

    // Initial state: set menu
    overlayKey.currentState!.setMenu(fakeMenu);
    await tester.pumpAndSettle();

    // The add reaction action should be visible
    final addReactionFinder = find.byIcon(Icons.add_reaction);
    expect(addReactionFinder, findsOneWidget);

    // Scenario 1: selectedEntry == null. Scrolling over primary menu should forward onScrolled (PR #950 behavior).
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(addReactionFinder),
        scrollDelta: const Offset(0, 20),
      ),
    );
    expect(scrollCount, 1,
        reason: 'Scroll over primary menu should forward when no secondary menu is open');

    // Open the secondary menu balloon
    await tester.tap(addReactionFinder);
    await tester.pumpAndSettle();

    final balloonFinder = find.byKey(const ValueKey('reaction_balloon'));
    expect(balloonFinder, findsOneWidget);

    // Scenario 2: selectedEntry != null. Scrolling inside the balloon should NOT forward onScrolled (Issue #58).
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(balloonFinder),
        scrollDelta: const Offset(0, 20),
      ),
    );
    expect(scrollCount, 1,
        reason: 'Scroll inside the emoji balloon must not forward to timeline behind it');

    // Also scrolling over the primary menu while the balloon is open should not forward to the timeline.
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(addReactionFinder),
        scrollDelta: const Offset(0, 20),
      ),
    );
    expect(scrollCount, 1,
        reason: 'Scroll over action bar when balloon is open must not forward to timeline');

    // Scenario 3: Close the balloon and verify that scrolling resumes forwarding to onScrolled.
    await tester.tap(addReactionFinder);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reaction_balloon')), findsNothing);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(addReactionFinder),
        scrollDelta: const Offset(0, 20),
      ),
    );
    expect(scrollCount, 2,
        reason: 'Scrolling should resume forwarding to timeline once secondary menu is closed');
  });

  testWidgets('EmojiPicker buildEmojiList has a Scrollbar', (tester) async {
    final pack = DynamicEmoticonPack(
      identifier: 'test_pack',
      displayName: 'Test Pack',
      emoticons: [
        _Emoticon('😀', shortcode: 'grinning'),
      ],
      usage: EmoticonUsage.emoji,
    );

    await tester.pumpWidget(
      _testApp(
        Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: EmojiPicker([pack]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(EmojiPicker),
        matching: find.byType(Scrollbar),
      ),
      findsOneWidget,
      reason: 'EmojiPicker list should have a Scrollbar on desktop',
    );
  });
}
