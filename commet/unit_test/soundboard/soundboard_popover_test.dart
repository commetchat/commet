import 'dart:convert';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_favorites.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

SoundboardSound _sound(String id, String name, [String emoji = '📢']) =>
    SoundboardSound(
      soundId: id,
      name: name,
      emoji: SoundboardEmoji.unicode(emoji),
      mediaUri: 'mxc://x/$id',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 1.0,
    );

SoundboardSource _source(String id, String name, List<SoundboardSound> s) =>
    SoundboardSource(
      id: id,
      name: name,
      color: Colors.blue,
      catalog: InMemorySoundboardCatalog(s),
    );

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      extensions: const [ThemeSettings()],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

// 1x1 transparent PNG, so a custom emoji has an image to render.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> played;
  late SoundboardFavorites favorites;
  late double volume;

  setUp(() {
    played = [];
    favorites = SoundboardFavorites.inMemory();
    volume = 0.8;
  });

  Future<void> pumpPopover(
    WidgetTester tester,
    List<SoundboardSource> sources,
  ) async {
    await tester.pumpWidget(_testApp(SoundboardPopover(
      sources: sources,
      favorites: favorites,
      onPlay: played.add,
      volume01: volume,
      onVolumeChanged: (v) => volume = v,
    )));
    await tester.pumpAndSettle();
  }

  testWidgets('shows one section per space and plays the tapped sound',
      (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [_sound('s1', 'Airhorn')]),
      _source('!b', 'Other space', [_sound('s2', 'Bruh')]),
    ]);

    expect(find.text('Roscas do CCO'), findsOneWidget);
    expect(find.text('Other space'), findsOneWidget);

    await tester.tap(find.text('Bruh'));
    expect(played, ['s2']);
  });

  testWidgets('search is focused on open and filters sounds by name',
      (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [
        _sound('s1', 'Airhorn'),
        _sound('s2', 'Sad trombone'),
      ]),
      _source('!b', 'Other space', [_sound('s3', 'Bruh')]),
    ]);

    // Typing without tapping first: the field has autofocus.
    await tester.enterText(find.byType(TextField), 'TROMB');
    await tester.pumpAndSettle();

    expect(find.text('Sad trombone'), findsOneWidget);
    expect(find.text('Airhorn'), findsNothing);
    expect(find.text('Bruh'), findsNothing);
    expect(find.text('Other space'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No sounds found'), findsOneWidget);
  });

  testWidgets('starring a sound adds a Favorites section at the top',
      (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [
        _sound('s1', 'Airhorn'),
        _sound('s2', 'Bruh'),
      ]),
    ]);
    expect(find.text('Favorites'), findsNothing);

    await tester.tap(find.byTooltip('Add Bruh to favorites'));
    await tester.pumpAndSettle();

    expect(favorites.ids, ['s2']);
    expect(find.text('Bruh'), findsNWidgets(2));
    final favoritesTop = tester.getTopLeft(find.text('Favorites')).dy;
    final spaceTop = tester.getTopLeft(find.text('Roscas do CCO')).dy;
    expect(favoritesTop, lessThan(spaceTop));

    // Playing from the favorites section plays the same sound.
    await tester.tap(find.text('Bruh').first);
    expect(played, ['s2']);

    await tester.tap(find.byTooltip('Remove Bruh from favorites').first);
    await tester.pumpAndSettle();
    expect(favorites.ids, isEmpty);
    expect(find.text('Favorites'), findsNothing);
  });

  testWidgets('favorites keep their order and skip removed sounds',
      (tester) async {
    favorites = SoundboardFavorites.inMemory(['gone', 's2', 's1']);
    await pumpPopover(tester, [
      _source('!a', 'A', [_sound('s1', 'Airhorn'), _sound('s2', 'Bruh')]),
    ]);

    final bruh = tester.getTopLeft(find.text('Bruh').first);
    final airhorn = tester.getTopLeft(find.text('Airhorn').first);
    expect(bruh.dy, airhorn.dy);
    expect(bruh.dx, lessThan(airhorn.dx));
    expect(find.text('Airhorn'), findsNWidgets(2));
  });

  testWidgets('tapping a section header collapses and expands it',
      (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [_sound('s1', 'Airhorn')]),
    ]);

    await tester.tap(find.text('Roscas do CCO'));
    await tester.pumpAndSettle();
    expect(find.text('Airhorn'), findsNothing);

    await tester.tap(find.text('Roscas do CCO'));
    await tester.pumpAndSettle();
    expect(find.text('Airhorn'), findsOneWidget);
  });

  testWidgets('the rail jumps to a space section', (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Big space', [
        for (var i = 0; i < 60; i++) _sound('a$i', 'Sound $i'),
      ]),
      _source('!b', 'Other space', [_sound('b1', 'Bruh')]),
    ]);
    expect(find.text('Bruh').hitTestable(), findsNothing);
    // No favorites yet, so the rail has no star.
    expect(find.byTooltip('Favorites'), findsNothing);

    await tester.tap(find.byTooltip('Other space'));
    await tester.pumpAndSettle();

    expect(find.text('Bruh').hitTestable(), findsOneWidget);
  });

  testWidgets('the rail only lists sections the search leaves visible',
      (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [_sound('s1', 'Airhorn')]),
      _source('!b', 'Other space', [_sound('s2', 'Bruh')]),
    ]);
    expect(find.byTooltip('Roscas do CCO'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bruh');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Roscas do CCO'), findsNothing);
    expect(find.byTooltip('Other space'), findsOneWidget);
  });

  testWidgets('volume lives in a secondary popover', (tester) async {
    await pumpPopover(tester, [
      _source('!a', 'A', [_sound('s1', 'Airhorn')]),
    ]);
    const sliderKey = ValueKey('soundboard-volume-slider');
    expect(find.byKey(sliderKey), findsNothing);

    await tester.tap(find.byTooltip('Sound effects volume'));
    await tester.pumpAndSettle();
    expect(find.text('80%'), findsOneWidget);

    await tester.drag(find.byKey(sliderKey), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(volume, 0.0);
    expect(find.text('0%'), findsOneWidget);

    // Tapping outside closes only the volume popover.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(sliderKey), findsNothing);
    expect(find.text('Airhorn'), findsOneWidget);
  });

  testWidgets('a custom Space emoji renders its image in the sound tile',
      (tester) async {
    // Issue #16 icons reach the issue #17 popover through the image
    // resolver; without one, only the unicode fallback can be shown.
    const velho = SoundboardEmoji.custom(
        mxc: 'mxc://example.org/velho', shortcode: ':velho:');
    final withImage = SoundboardSound(
      soundId: 's1',
      name: 'Velho',
      emoji: velho,
      mediaUri: 'mxc://x/s1',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 1.0,
    );

    await tester.pumpWidget(_testApp(SoundboardPopover(
      sources: [
        _source('!a', 'Roscas do CCO', [withImage])
      ],
      favorites: favorites,
      onPlay: played.add,
      volume01: volume,
      onVolumeChanged: (v) => volume = v,
      imageFor: (emoji) => emoji == velho ? _pixel : null,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(SoundboardEmoji.fallback), findsNothing);
  });

  testWidgets('a custom Space emoji without an image shows the fallback',
      (tester) async {
    final noImage = SoundboardSound(
      soundId: 's1',
      name: 'Velho',
      emoji: const SoundboardEmoji.custom(
          mxc: 'mxc://example.org/velho', shortcode: ':velho:'),
      mediaUri: 'mxc://x/s1',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 1.0,
    );

    await pumpPopover(tester, [
      _source('!a', 'Roscas do CCO', [noImage]),
    ]);

    expect(find.text(SoundboardEmoji.fallback), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
