// TEMPORARY diagnostics for failed MyInstants imports. Delete this file and
// the `_probeNetwork` call in SpaceSoundboardSettingsPage once imports are
// confirmed working on Windows.
//
// Logs what dart:io sees from inside the running app for each host an
// import needs: one lookup per address family, then a GET with a fresh
// HttpClient and Dart's default headers. dart:io connects after separate
// IPv4 and IPv6 lookups and only fails if both fail, but the failing half
// still reaches Log.spec's errorCallback. That is where "ERROR CALLBACK ...
// Failed host lookup ... errno = 11004" comes from while requests succeed.
import 'dart:async';
import 'dart:io';

Future<void> probeNetwork(
    List<Uri> uris, void Function(String line) log) async {
  for (final uri in uris) {
    for (final type in [
      InternetAddressType.any,
      InternetAddressType.IPv4,
      InternetAddressType.IPv6,
    ]) {
      try {
        final addresses = await InternetAddress.lookup(uri.host, type: type)
            .timeout(const Duration(seconds: 10));
        log('probe: lookup ${uri.host} ${type.name}: '
            '${addresses.map((a) => a.address).join(' ')}');
      } catch (e) {
        log('probe: lookup ${uri.host} ${type.name} failed: $e');
      }
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      await response.drain<void>();
      log('probe: GET $uri -> ${response.statusCode} '
          '(server=${response.headers.value('server')}, '
          'cf-ray=${response.headers.value('cf-ray')})');
    } catch (e) {
      log('probe: GET $uri failed: $e');
    } finally {
      client.close(force: true);
    }
  }
}
