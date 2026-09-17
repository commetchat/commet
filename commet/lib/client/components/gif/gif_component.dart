import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/widgets.dart';

abstract class FavoriteGif {
  ImageProvider get image;

  String get url;

  double get width;

  double get height;
}

abstract class GifComponent<T extends Client> implements Component<T> {
  /// Throws if the request fails, returns an empty page if there are no results
  Future<GifSearchPage> search(String query, {String? pos});

  /// Trending gifs, empty if the service or proxy does not support it
  Future<GifSearchPage> trending({String? pos});

  Future<TimelineEvent?> sendGif(
      Room room, GifSearchResult gif, TimelineEvent? inReplyTo);

  Future<TimelineEvent?> sendFavoriteGif(
      Room room, FavoriteGif gif, TimelineEvent? inReplyTo);

  String get searchPlaceholder;

  bool isGif(TimelineEvent event);

  bool isFavoriteGif(TimelineEvent event);

  Stream get onFavoritesChanged;

  Future<void> setFavoriteFromEvent(TimelineEvent event);

  Future<void> removeFavoriteFromEvent(TimelineEvent event);

  Future<void> removeFavorite(FavoriteGif gif);

  List<FavoriteGif> get favorites;
}
