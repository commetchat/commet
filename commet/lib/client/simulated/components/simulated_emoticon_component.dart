import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/simulated/simulated_client.dart';

class SimulatedEmoticonComponent implements EmoticonComponent<SimulatedClient> {
  @override
  SimulatedClient client;

  SimulatedEmoticonComponent(this.client);

  StreamController<int> onPackAdded = StreamController();

  @override
  bool get canCreatePack => false;

  @override
  Future<void> createEmoticonPack(String name, Uint8List? avatarData) async {}

  @override
  Future<void> deleteEmoticonPack(EmoticonPack pack) async {}

  @override
  List<EmoticonPack> globalPacks() {
    return [];
  }

  @override
  Stream<int> get onOwnedPackAdded => onPackAdded.stream;

  @override
  List<EmoticonPack> get ownedPacks => [];
}
