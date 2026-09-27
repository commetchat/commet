// Finds the links in what the DJ pasted. Pure string work, shared by the add
// bar (to say which source takes a link before resolving it) and the
// session. What a link holds is up to the source extension that takes it
// (docs/dj-extensions.md).

class DjLink {
  /// The link, normalised: `https://`, no tracking parameters.
  final String url;

  /// Lowercase host.
  final String host;

  const DjLink(this.url, this.host);

  @override
  bool operator ==(Object other) => other is DjLink && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'DjLink($url)';
}

class DjLinks {
  static final RegExp _urlPattern = RegExp(r'https?://[^\s<>"]+');

  /// Every link in [text] (pasted text can hold several, one per line),
  /// in order, without duplicates.
  static List<DjLink> parseAll(String text) {
    final found = <DjLink>[];
    final seen = <String>{};
    for (final match in _urlPattern.allMatches(text)) {
      final link = parse(_trimPunctuation(match[0]!));
      if (link != null && seen.add(link.url)) found.add(link);
    }
    return found;
  }

  static String _trimPunctuation(String url) =>
      url.replaceFirst(RegExp(r'[).,;!?\]]+$'), '');

  /// What [input] links to; null when it is not an http(s) link.
  static DjLink? parse(String input) {
    try {
      final uri = Uri.tryParse(input.trim());
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return null;
      }
      if (uri.host.isEmpty) return null;
      return DjLink(_clean(uri).toString(), uri.host.toLowerCase());
    } on FormatException {
      // Malformed percent-encoding in the query or path.
      return null;
    }
  }

  static Uri _clean(Uri uri) {
    final query = Map.of(uri.queryParameters)
      ..removeWhere((k, _) => k.startsWith('utm_') || k == 'si');
    // Built anew: `replace` keeps the old query when given none.
    return Uri(
      scheme: 'https',
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters: query.isEmpty ? null : query,
      fragment: uri.hasFragment ? uri.fragment : null,
    );
  }

  /// Whether [host] is taken by a source that lists [pattern]: the same
  /// host, or one under it (`www.example.org` for `example.org`).
  static bool hostMatches(String host, String pattern) {
    final h = host.toLowerCase();
    final p = pattern.toLowerCase();
    return h == p || h.endsWith('.$p');
  }
}
