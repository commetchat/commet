import 'package:commet/client/attachment.dart';
import 'package:matrix/matrix.dart';

class MatrixProcessedAttachment extends ProcessedAttachment {
  MatrixFile file;

  MatrixProcessedAttachment(this.file);
}
