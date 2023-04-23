import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'cached_file.g.dart';

@HiveType(typeId: 100)
class CachedFile extends HiveObject {
  CachedFile(this.filePath, this.lastAccessedTimestamp);

  @HiveField(0)
  String filePath;

  @HiveField(1)
  int lastAccessedTimestamp;
}
