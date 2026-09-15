enum DataStreamErrorReason {
  // Unable to open a stream with the same ID more than once.
  AlreadyOpened,

  // Stream closed abnormally by remote participant.
  AbnormalEnd,

  // Incoming chunk data could not be decoded.
  DecodeFailed,

  // Read length exceeded total length specified in stream header.
  LengthExceeded,

  // Read length less than total length specified in stream header.
  Incomplete,

  // Unable to register a stream handler more than once.
  HandlerAlreadyRegistered,

  // Encryption type mismatch.
  EncryptionTypeMismatch,
}

class DataStreamError implements Exception {
  final DataStreamErrorReason reason;
  final String message;

  DataStreamError({required this.reason, required this.message});

  @override
  String toString() {
    return 'DataStreamError: $reason, $message';
  }
}
