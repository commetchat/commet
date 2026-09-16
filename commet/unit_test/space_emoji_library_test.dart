import 'package:commet/client/components/emoticon/space_emoji_library.dart';
import 'package:test/test.dart';

void main() {
  group('SpaceEmojiLibrary.validateShortcode', () {
    test('accepts letters, digits and underscores, stripping colons', () {
      expect(SpaceEmojiLibrary.validateShortcode('velho'), 'velho');
      expect(SpaceEmojiLibrary.validateShortcode(' :Big_Cat2: '), 'Big_Cat2');
    });

    test('rejects too short, too long and invalid characters', () {
      for (final bad in ['', 'a', ':a:', 'x' * 33, 'has space', 'dash-y']) {
        expect(() => SpaceEmojiLibrary.validateShortcode(bad),
            throwsA(isA<SpaceEmojiError>()),
            reason: bad);
      }
      expect(SpaceEmojiLibrary.validateShortcode('x' * 32), 'x' * 32);
    });
  });

  group('SpaceEmojiLibrary.shortcodeFromFilename', () {
    test('turns a file name into a valid shortcode', () {
      String fromName(String name) =>
          SpaceEmojiLibrary.shortcodeFromFilename(name, const {});

      expect(fromName('velho.png'), 'velho');
      expect(fromName('C:\\pics\\Old Man (1).final.gif'), 'Old_Man_1_final');
      expect(fromName('/tmp/ç.png'), 'emoji');
      expect(fromName('x.png'), 'x_');
      expect(fromName('${'a' * 40}.png'), 'a' * 32);
    });

    test('appends a number when the name is taken', () {
      expect(
          SpaceEmojiLibrary.shortcodeFromFilename(
              'velho.png', {'velho', 'velho_2'}),
          'velho_3');
      expect(
          SpaceEmojiLibrary.shortcodeFromFilename(
              '${'a' * 40}.png', {'a' * 32}),
          '${'a' * 30}_2');
    });
  });

  group('SpaceEmojiLibrary listing', () {
    final library = SpaceEmojiLibrary({
      'memes': {
        'pack': {'display_name': 'Memes'},
        'images': {
          'velho': {'url': 'mxc://x/memes-velho'},
          'cat': {'url': 'mxc://x/cat'},
          'big_sticker': {
            'url': 'mxc://x/sticker',
            'usage': ['sticker'],
          },
        },
      },
      'deleted': <String, dynamic>{},
      'stickers_only': {
        'pack': {
          'usage': ['sticker'],
        },
        'images': {
          'wave': {'url': 'mxc://x/wave'},
          'dog': {
            'url': 'mxc://x/dog',
            'usage': ['emoticon'],
          },
        },
      },
      SpaceEmojiLibrary.defaultPackKey: {
        'images': {
          'velho': {'url': 'mxc://x/server-velho'},
          'broken': {'no_url': true},
        },
      },
    });

    test('lists emoji-usable images, server pack first, first name wins', () {
      expect(
          library.emoji
              .map((e) => '${e.packKey}/${e.shortcode}=${e.url}')
              .toList(),
          [
            'server_emojis/velho=mxc://x/server-velho',
            'memes/cat=mxc://x/cat',
            'stickers_only/dog=mxc://x/dog',
          ]);
    });

    test('counts every image in every pack against the quota', () {
      expect(SpaceEmojiLibrary.quota, 50);
      expect(library.usedSlots, 6);
      expect(library.freeSlots, 44);
      expect(SpaceEmojiLibrary(const {}).usedSlots, 0);
    });
  });

  group('SpaceEmojiLibrary.add', () {
    test('creates the server pack on first upload', () {
      final edit = SpaceEmojiLibrary(const {}).add(':velho:', 'mxc://x/v');

      expect(edit.packKey, 'server_emojis');
      expect(edit.content, {
        'pack': {'display_name': 'Server Emojis'},
        'images': {
          'velho': {'url': 'mxc://x/v'},
        },
      });
    });

    test('appends to the existing server pack without mutating it', () {
      final state = {
        'server_emojis': {
          'pack': {'display_name': 'Ours', 'avatar_url': 'mxc://x/a'},
          'images': {
            'cat': {'url': 'mxc://x/cat', 'body': 'cat'},
          },
        },
      };

      final edit = SpaceEmojiLibrary(state).add('velho', 'mxc://x/v');

      expect(edit.content, {
        'pack': {'display_name': 'Ours', 'avatar_url': 'mxc://x/a'},
        'images': {
          'cat': {'url': 'mxc://x/cat', 'body': 'cat'},
          'velho': {'url': 'mxc://x/v'},
        },
      });
      expect((state['server_emojis']!['images'] as Map).keys, ['cat']);
    });

    test('rejects taken names, invalid names and a full quota', () {
      final library = SpaceEmojiLibrary({
        'other': {
          'images': {
            'cat': {'url': 'mxc://x/cat'},
          },
        },
      });
      expect(() => library.add('cat', 'mxc://x/2'),
          throwsA(isA<SpaceEmojiError>()));
      expect(() => library.add('no way', 'mxc://x/2'),
          throwsA(isA<SpaceEmojiError>()));

      final full = SpaceEmojiLibrary({
        'server_emojis': {
          'images': {
            for (var i = 0; i < 50; i++) 'e$i': {'url': 'mxc://x/$i'},
          },
        },
      });
      expect(full.freeSlots, 0);
      expect(() => full.add('one_more', 'mxc://x/2'),
          throwsA(isA<SpaceEmojiError>()));
    });
  });

  group('SpaceEmojiLibrary.rename', () {
    Map<String, dynamic> state() => {
          'memes': {
            'pack': {'display_name': 'Memes'},
            'images': {
              'a': {'url': 'mxc://x/a'},
              'old': {
                'url': 'mxc://x/old',
                'usage': ['emoticon'],
              },
              'z': {'url': 'mxc://x/z'},
            },
          },
          'server_emojis': {
            'images': {
              'taken': {'url': 'mxc://x/t'},
            },
          },
        };

    test('renames in the owning pack, keeping order and fields', () {
      final input = state();
      final edit = SpaceEmojiLibrary(input).rename('old', ':velho:');

      expect(edit.packKey, 'memes');
      expect(edit.content, {
        'pack': {'display_name': 'Memes'},
        'images': {
          'a': {'url': 'mxc://x/a'},
          'velho': {
            'url': 'mxc://x/old',
            'usage': ['emoticon'],
          },
          'z': {'url': 'mxc://x/z'},
        },
      });
      expect(input, state());
    });

    test('rejects unknown emoji and names taken by another emoji', () {
      final library = SpaceEmojiLibrary(state());
      expect(() => library.rename('missing', 'new_name'),
          throwsA(isA<SpaceEmojiError>()));
      expect(() => library.rename('old', 'taken'),
          throwsA(isA<SpaceEmojiError>()));
      expect(library.rename('old', 'old').content, state()['memes']);
    });
  });

  group('SpaceEmojiLibrary.remove', () {
    test('removes the image from its pack, freeing the slot', () {
      final input = {
        'server_emojis': {
          'pack': {'display_name': 'Server Emojis'},
          'images': {
            'cat': {'url': 'mxc://x/cat'},
            'velho': {'url': 'mxc://x/v'},
          },
        },
      };
      final library = SpaceEmojiLibrary(input);

      final edit = library.remove('velho');

      expect(edit.packKey, 'server_emojis');
      expect(edit.content, {
        'pack': {'display_name': 'Server Emojis'},
        'images': {
          'cat': {'url': 'mxc://x/cat'},
        },
      });
      expect(library.usedSlots, 2);
      expect(SpaceEmojiLibrary({edit.packKey: edit.content}).usedSlots, 1);
      expect(() => library.remove('dog'), throwsA(isA<SpaceEmojiError>()));
    });
  });
}
