import 'package:isar/isar.dart';

part 'cached_file.g.dart';

@collection
class CachedFile {
  CachedFile(this.filePath, this.fileId, this.lastAccessedTimestamp);

  Id id = Isar.autoIncrement;

  String fileId;

  String filePath;

  int lastAccessedTimestamp;
}
