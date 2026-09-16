import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:test/test.dart';

/// Nothing cached; only the calls a media download makes are implemented.
class _EmptyDatabase implements matrix.DatabaseApi {
  @override
  Future<({Map<String, Object?> content, DateTime savedAt})?>
      getCustomCacheObject(String cacheKey) async => null;

  @override
  Future<void> cacheCustomObject(
      String cacheKey, Map<String, Object?> object) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('downloads an mxc:// URI by its media ID', () async {
    final requested = <String>[];
    final client = matrix.Client(
      'test',
      database: _EmptyDatabase(),
      httpClient: MockClient((request) async {
        requested.add(request.url.path);
        if (request.url.path == '/_matrix/client/versions') {
          return http.Response('{"versions": ["v1.11"]}', 200);
        }
        return http.Response.bytes([1, 2, 3], 200);
      }),
    )
      ..homeserver = Uri.parse('https://hs.example')
      ..accessToken = 'token';

    final bytes =
        await MxcFileProvider(client, Uri.parse('mxc://hs.example/AbCd'))
            .getFileData();

    expect(bytes, [1, 2, 3]);
    // Not ".../hs.example/%2FAbCd", which is what passing uri.path produced.
    expect(requested.last, '/_matrix/client/v1/media/download/hs.example/AbCd');
  });
}
