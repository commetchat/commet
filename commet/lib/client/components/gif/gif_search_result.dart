class GifSearchResult {
  final Uri previewUrl;
  final Uri fullResUrl;
  final double x;
  final double y;
  final String mimeType;
  final String? id;

  GifSearchResult(
      this.previewUrl, this.fullResUrl, this.x, this.y, this.mimeType,
      {this.id});
}

// COMMET: one page of results, [next] is the cursor for the following page
class GifSearchPage {
  final List<GifSearchResult> results;
  final String? next;

  const GifSearchPage(this.results, {this.next});

  static const empty = GifSearchPage([]);
}
