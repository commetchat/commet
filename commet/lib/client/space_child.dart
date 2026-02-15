import 'package:commet/client/client.dart';

abstract class SpaceChild<T> {
  String get id;
  final T child;

  SpaceChild(this.child);
}

class SpaceChildRoom<T extends Room> implements SpaceChild<T> {
  @override
  final T child;

  @override
  String get id => child.roomId;

  SpaceChildRoom(this.child);
}

class SpaceChildSpace<T extends Space> implements SpaceChild<T> {
  @override
  final T child;

  @override
  String get id => child.identifier;

  SpaceChildSpace(this.child);
}
