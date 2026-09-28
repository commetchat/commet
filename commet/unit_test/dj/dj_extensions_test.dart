// Source extensions as the booth runs them (docs/dj-extensions.md): a fake
// extension, a shell script, answers the way the protocol says, and the
// booth takes from it only what the protocol allows.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:commet/client/components/dj/dj_extension_manifest.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/matrix/components/dj/native/dj_extension_resolver.dart';
import 'package:commet/client/matrix/components/dj/native/dj_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _script = r'''
verb="$1"
req="$2"
field() { echo "$req" | sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"; }
case "$req" in *'"protocol":1'*) ;; *) echo '{"error":"no protocol"}'; exit 1 ;; esac
[ -d "$(field data)" ] || { echo '{"error":"no data folder"}'; exit 1; }
case "$verb" in
  resolve)
    echo "not JSON, ignored"
    case "$(field url)" in
      */bad) echo '{"error":"Nothing playable in that link"}'; exit 1 ;;
      */silent) echo 'it broke' >&2; exit 1 ;;
    esac
    echo '{"tracks":[{"source":"https://music.example/1","title":"One","label":"Example","durationMs":1000,"thumbnail":"http://insecure.example/x.jpg","link":"javascript:alert(1)"},{"title":"no source"},{"source":"search:two","title":"Two","artist":"Band","link":"https://songs.example/2","thumbnail":"https://art.example/2.jpg"}]}'
    ;;
  fetch)
    dir="$(field directory)"; name="$(field name)"
    case "$(field source)" in
      */outside)
        echo "{\"started\":{\"path\":\"/tmp/$name.mp3\"}}"
        echo "{\"done\":{\"path\":\"/tmp/$name.mp3\"}}" ;;
      *)
        echo "{\"started\":{\"path\":\"$dir/$name.mp3\",\"size\":3,\"title\":\"One\",\"audio\":\"mp3\"}}"
        printf abc > "$dir/$name.mp3"
        echo "{\"done\":{\"path\":\"$dir/$name.mp3\"}}" ;;
    esac
    ;;
esac
''';

Future<InstalledDjExtension> _fakeExtension(Directory dir) async {
  await File(p.join(dir.path, 'ext.sh')).writeAsString(_script);
  final manifest = DjExtensionManifest.parse(jsonEncode({
    'protocol': 1,
    'id': 'org.example.fake',
    'name': 'Fake',
    'version': '1',
    'hosts': ['music.example'],
    'run': {
      'command': '/bin/sh',
      'args': ['{dir}/ext.sh'],
    },
  }));
  return InstalledDjExtension(manifest, dir);
}

Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dj-ext-test-');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  group('running an extension', () {
    test('resolve gives its tracks, keeping only what is safe', () async {
      final extension = await _fakeExtension(temp);
      final answer =
          await DjExtensions.resolve(extension, 'https://music.example/list');
      var n = 0;
      final tracks = DjExtensionResolver.tracksFrom(answer,
          extensionId: extension.id, addedBy: '@a:x', newId: () => 'id${n++}');

      expect(tracks.map((t) => t.source), [
        'ext:org.example.fake:https://music.example/1',
        'ext:org.example.fake:search:two',
      ]);
      final one = tracks.first;
      expect(one.kind, 'Example');
      expect(one.durationMs, 1000);
      // Not https, not a web page: left out.
      expect(one.thumbnail, isNull);
      expect(one.link, isNull);
      expect(one.pageUrl, 'https://music.example/1');
      final two = tracks.last;
      expect(two.kind, DjTrack.linkKind);
      expect(two.link, 'https://songs.example/2');
      expect(two.thumbnail, 'https://art.example/2.jpg');
      expect(two.artist, 'Band');
      expect(two.addedBy, '@a:x');
    });

    test("an extension's error is the user's message", () async {
      final extension = await _fakeExtension(temp);
      expect(
          DjExtensions.resolve(extension, 'https://music.example/bad'),
          throwsA(isA<DjExtensionException>().having(
              (e) => e.message, 'message', 'Nothing playable in that link')));
    });

    test('silence ends with what it said on stderr', () async {
      final extension = await _fakeExtension(temp);
      expect(
          DjExtensions.resolve(extension, 'https://music.example/silent'),
          throwsA(isA<DjExtensionException>()
              .having((e) => e.message, 'message', 'Fake failed: it broke')));
    });

    test('fetch reports the file before it is done, then done', () async {
      final extension = await _fakeExtension(temp);
      final songs = await Directory(p.join(temp.path, 'songs')).create();
      final fetch = DjExtensions.fetch(extension, 'https://music.example/1',
          directory: songs.path, name: 'key1', trusted: false);
      final (path, info) = await fetch.started;
      expect(path, p.join(songs.path, 'key1.mp3'));
      expect(info['size'], 3);
      expect(info['audio'], 'mp3');
      expect(await fetch.finished, path);
      expect(await File(path).readAsString(), 'abc');
    });

    test('a file outside the one asked for is not taken', () async {
      final extension = await _fakeExtension(temp);
      final songs = await Directory(p.join(temp.path, 'songs')).create();
      final fetch = DjExtensions.fetch(
          extension, 'https://music.example/outside',
          directory: songs.path, name: 'key2', trusted: true);
      await expectLater(fetch.finished, throwsA(isA<DjExtensionException>()));
    });

    test('a missing program says to install it again', () async {
      final manifest = DjExtensionManifest.parse(jsonEncode({
        'protocol': 1,
        'id': 'org.example.gone',
        'name': 'Gone',
        'version': '1',
        'run': {'command': '{dir}/nothing-here'},
      }));
      expect(
          DjExtensions.resolve(
              InstalledDjExtension(manifest, temp), 'https://x.example/'),
          throwsA(isA<DjExtensionException>().having(
              (e) => e.message, 'message', contains('installing it again'))));
    });
  }, skip: Platform.isLinux ? false : 'runs a shell script');

  group('reading a package', () {
    final manifest = jsonEncode({
      'protocol': 1,
      'id': 'org.example.music',
      'name': 'Example music',
      'version': '2.0',
      'downloads': [
        {
          'id': 'tool',
          'name': 'Tool',
          'size': '1 MB',
          'files': {
            for (final platform in ['linux-x64', 'linux-arm64', 'windows-x64'])
              platform: {'url': 'https://example.org/tool'}
          },
        },
      ],
      'run': {'command': '{dep:tool}'},
    });

    test('shows what it is and what it downloads', () {
      final package = DjExtensions.openBytes(
          _zip({DjExtensionManifest.fileName: manifest, 'main.ts': ''}),
          from: 'https://example.org/ext.zip');
      expect(package.info.name, 'Example music');
      expect(package.info.version, '2.0');
      expect(package.info.installedFrom, 'https://example.org/ext.zip');
      expect(package.downloads, [('Tool', '1 MB')]);
      expect(package.problem, isNull);
    });

    test('not a zip, or no manifest at its root', () {
      expect(() => DjExtensions.openBytes(Uint8List.fromList([1, 2, 3])),
          throwsA(isA<DjExtensionException>()));
      expect(
          () => DjExtensions.openBytes(
              _zip({'inner/${DjExtensionManifest.fileName}': manifest})),
          throwsA(isA<DjExtensionException>()));
    });

    test('files that would land outside its folder are refused', () async {
      for (final name in ['../evil.sh', 'a/../../evil.sh', '/etc/evil']) {
        final archive = ZipDecoder().decodeBytes(_zip({name: 'x'}));
        final into = await Directory(p.join(temp.path, 'x')).create();
        await expectLater(DjExtensions.unpack(archive, into),
            throwsA(isA<DjExtensionException>()),
            reason: name);
      }
      expect(File(p.join(temp.path, 'evil.sh')).existsSync(), isFalse);
    });

    test('its files unpack under its folder', () async {
      final archive = ZipDecoder().decodeBytes(_zip({
        DjExtensionManifest.fileName: manifest,
        'src/deep/main.ts': 'hello',
      }));
      final into = await Directory(p.join(temp.path, 'ok')).create();
      await DjExtensions.unpack(archive, into);
      expect(
          await File(p.join(into.path, 'src', 'deep', 'main.ts'))
              .readAsString(),
          'hello');
    });
  });
}
