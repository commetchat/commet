// The manifest of a DJ source extension (docs/dj-extensions.md): what is
// taken, and what is turned down before anything is downloaded or run.
import 'dart:convert';

import 'package:commet/client/components/dj/dj_extension_manifest.dart';
import 'package:test/test.dart';

Map<String, Object?> manifest() => {
      'protocol': 1,
      'id': 'org.example.music',
      'name': 'Example music',
      'version': '1.2.0',
      'description': 'Plays Example links.',
      'homepage': 'https://example.org/music',
      'hosts': ['example.org', 'Music.Example.NET'],
      'hint': 'Paste an Example link',
      'downloads': [
        {
          'id': 'runtime',
          'name': 'Runtime',
          'size': '45 MB',
          'files': {
            'linux-x64': {
              'url': 'https://example.org/runtime-linux.zip',
              'unzip': 'bin/runtime',
              'sha256': 'AB' * 32,
            },
            'windows-x64': {'url': 'https://example.org/runtime.exe'},
          },
        },
      ],
      'run': {
        'command': '{dep:runtime}',
        'args': ['run', '{dir}/main.ts', '--data={dir}/x'],
      },
    };

DjExtensionManifest parse(Map<String, Object?> json) =>
    DjExtensionManifest.parse(jsonEncode(json));

Matcher refused(String containing) => throwsA(isA<DjExtensionManifestException>()
    .having((e) => e.message, 'message', contains(containing)));

void main() {
  test('a whole manifest reads back', () {
    final m = parse(manifest());
    expect(m.id, 'org.example.music');
    expect(m.name, 'Example music');
    expect(m.version, '1.2.0');
    expect(m.hint, 'Paste an Example link');
    expect(m.hosts, ['example.org', 'music.example.net']);
    final download = m.downloads.single;
    expect(download.size, '45 MB');
    expect(download.files['linux-x64']!.sha256, 'ab' * 32);
    expect(download.files['linux-x64']!.unzip, 'bin/runtime');
  });

  test('links are taken by host, and "*" takes the rest', () {
    final m = parse(manifest());
    expect(m.takesHost('example.org'), isTrue);
    expect(m.takesHost('www.example.org'), isTrue);
    expect(m.takesHost('music.example.net'), isTrue);
    expect(m.takesHost('notexample.org'), isFalse);
    expect(m.takesAnyLink, isFalse);

    final any = parse({
      ...manifest(),
      'hosts': ['*']
    });
    expect(any.takesAnyLink, isTrue);
    expect(any.takesHost('example.org'), isFalse);
  });

  test('the command line fills in its folder and downloads', () {
    final m = parse(manifest());
    expect(
        m.commandLine(dir: '/ext', dep: (id) => '/ext/deps/$id'),
        ['/ext/deps/runtime', 'run', '/ext/main.ts', '--data=/ext/x']);
  });

  test('files for this platform, or none when a download lacks it', () {
    final m = parse(manifest());
    expect(m.filesFor('windows-x64')!.single.$2.url,
        'https://example.org/runtime.exe');
    expect(m.filesFor('linux-arm64'), isNull);
    final nothing = parse({
      ...manifest(),
      'downloads': <Object>[],
      'run': {'command': 'music'},
    });
    expect(nothing.filesFor('linux-arm64'), isEmpty);
  });

  group('turned down', () {
    test('not JSON, or not an object', () {
      expect(() => DjExtensionManifest.parse('{'), refused('valid JSON'));
      expect(() => DjExtensionManifest.parse('[]'), refused('JSON object'));
    });

    test('another protocol', () {
      expect(() => parse({...manifest(), 'protocol': 2}), refused('protocol'));
      expect(() => parse({...manifest()}..remove('protocol')),
          refused('protocol'));
    });

    test('a bad id', () {
      for (final id in ['ab', 'Org.Example', 'a/b', '../x', 'x' * 65]) {
        expect(() => parse({...manifest(), 'id': id}), refused('"id"'),
            reason: id);
      }
    });

    test('no name, version or run', () {
      expect(() => parse({...manifest()}..remove('name')), refused('"name"'));
      expect(() => parse({...manifest()}..remove('version')),
          refused('"version"'));
      expect(() => parse({...manifest()}..remove('run')), refused('"run"'));
    });

    test('a download over plain http', () {
      final json = manifest();
      ((json['downloads'] as List).first as Map)['files'] = {
        'linux-x64': {'url': 'http://example.org/runtime'}
      };
      expect(() => parse(json), refused('not https'));
    });

    test('a file taken from outside its download', () {
      for (final unzip in ['../evil', '/etc/passwd', r'\evil', 'a/../../b']) {
        final json = manifest();
        ((json['downloads'] as List).first as Map)['files'] = {
          'linux-x64': {'url': 'https://example.org/r.zip', 'unzip': unzip}
        };
        expect(() => parse(json), refused('outside'), reason: unzip);
      }
    });

    test('a bad checksum', () {
      final json = manifest();
      ((json['downloads'] as List).first as Map)['files'] = {
        'linux-x64': {'url': 'https://example.org/r', 'sha256': 'abc'}
      };
      expect(() => parse(json), refused('sha256'));
    });

    test('running a download it does not have', () {
      expect(
          () => parse({
                ...manifest(),
                'run': {'command': '{dep:other}'}
              }),
          refused('"other"'));
    });

    test('a homepage that is not https', () {
      expect(() => parse({...manifest(), 'homepage': 'javascript:alert(1)'}),
          refused('homepage'));
    });

    test('two downloads with one id', () {
      final json = manifest();
      final downloads = json['downloads'] as List;
      json['downloads'] = [downloads.first, downloads.first];
      expect(() => parse(json), refused('repeated'));
    });
  });
}
