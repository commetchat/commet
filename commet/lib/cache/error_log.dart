class ErrorEntry {
  String stackTrace;
  String detail;
  DateTime lastOccurred;
  int occurrences;

  ErrorEntry({
    required this.stackTrace,
    required this.detail,
    required this.lastOccurred,
    required this.occurrences,
  });
}

abstract class ErrorLog {
  Future<void> storeError(String stackTrace, String detail, String type);

  Future<List<ErrorEntry>> getErrors();
}
