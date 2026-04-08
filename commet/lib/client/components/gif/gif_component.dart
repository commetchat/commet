import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/widgets.dart';

abstract class FavoriteGif {
  ImageProvider get image;

  double get width;

  double get height;
}

abstract class GifComponent<T extends Client> implements Component<T> {
  Future<List<GifSearchResult>> search(String query);

  Future<TimelineEvent?> sendGif(
      Room room, GifSearchResult gif, TimelineEvent? inReplyTo);

  Future<TimelineEvent?> sendFavoriteGif(
      Room room, FavoriteGif gif, TimelineEvent? inReplyTo);

  String get searchPlaceholder;

  bool isGif(TimelineEvent event);

  bool isFavoriteGif(TimelineEvent event);

  Stream get onFavoritesChanged;

  Future<void> setFavorite(TimelineEvent event);

  Future<void> removeFavorite(TimelineEvent event);

  List<FavoriteGif> get favorites;
}
