import 'dart:convert';

import 'package:commet/client/components/emoticon/dynamic_emoticon_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/ui/molecules/soundboard_emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class _Emoticon implements Emoticon {
  @override
  final String slug;
  @override
  final String key;
  @override
  final String? shortcode;
  @override
  final ImageProvider? image;

  _Emoticon(this.slug, {String? key, this.shortcode, this.image})
      : key = key ?? slug;

  @override
  EmoticonUsage get usage => EmoticonUsage.emoji;
  @override
  bool get isEmoji => true;
  @override
  bool get isSticker => false;
}

// 1x1 transparent PNG, so custom emoticons have an image to render.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='));

final _velho = _Emoticon(':velho:',
    key: 'mxc://example.org/velho', shortcode: 'velho', image: _pixel);
final _horn = _Emoticon('📯', shortcode: 'postal_horn');

final _packs = [
  DynamicEmoticonPack(
      identifier: 'space',
      displayName: 'My Space',
      emoticons: [_velho],
      usage: EmoticonUsage.emoji),
  DynamicEmoticonPack(
      identifier: 'unicode',
      displayName: 'Objects',
      emoticons: [_horn],
      usage: EmoticonUsage.emoji),
];

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: const [ThemeSettings()],
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('soundboardEmojiFromEmoticon', () {
    test('maps a unicode emoticon to its character', () {
      expect(soundboardEmojiFromEmoticon(_horn),
          const SoundboardEmoji.unicode('📯'));
    });

    test('maps a custom emoticon to its mxc image and shortcode', () {
      expect(
          soundboardEmojiFromEmoticon(_velho),
          const SoundboardEmoji.custom(
              mxc: 'mxc://example.org/velho', shortcode: ':velho:'));
    });
  });

  group('SoundboardEmojiPickerButton', () {
    testWidgets('picks a space emoji from the popover', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SoundboardEmoji? picked;
      await tester.pumpWidget(_app(SoundboardEmojiPickerButton(
        value: const SoundboardEmoji.unicode('📢'),
        packs: _packs,
        onChanged: (e) => picked = e,
      )));

      expect(find.text('📢'), findsOneWidget);
      expect(find.text('My Space'), findsNothing);

      await tester.tap(find.byType(SoundboardEmojiPickerButton));
      await tester.pumpAndSettle();
      expect(find.text('My Space'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);

      await tester.tap(
          find.byWidgetPredicate((w) => w is FadeInImage && w.image == _pixel));
      await tester.pumpAndSettle();

      expect(
          picked,
          const SoundboardEmoji.custom(
              mxc: 'mxc://example.org/velho', shortcode: ':velho:'));
      expect(find.text('My Space'), findsNothing, reason: 'popover closes');
    });

    testWidgets('searches emoji by shortcode', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SoundboardEmoji? picked;
      await tester.pumpWidget(_app(SoundboardEmojiPickerButton(
        value: const SoundboardEmoji.unicode('📢'),
        packs: _packs,
        onChanged: (e) => picked = e,
      )));
      await tester.tap(find.byType(SoundboardEmojiPickerButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'postal');
      await tester.pumpAndSettle();
      expect(find.text('My Space'), findsNothing);

      await tester.tap(find.text('📯'));
      await tester.pumpAndSettle();
      expect(picked, const SoundboardEmoji.unicode('📯'));
    });

    testWidgets('shows the custom emoji image for the current value',
        (tester) async {
      await tester.pumpWidget(_app(SoundboardEmojiPickerButton(
        value: const SoundboardEmoji.custom(
            mxc: 'mxc://example.org/velho', shortcode: ':velho:'),
        packs: _packs,
        imageFor: (e) => e.mxc == 'mxc://example.org/velho' ? _pixel : null,
        onChanged: (_) {},
      )));
      expect(find.byWidgetPredicate((w) => w is Image && w.image == _pixel),
          findsOneWidget);
      expect(find.text('🔊'), findsNothing);
    });
  });
}
