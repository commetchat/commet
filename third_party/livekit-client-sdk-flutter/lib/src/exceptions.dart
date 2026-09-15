// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Base class for Exceptions thrown by the LiveKit SDK
abstract class LiveKitException implements Exception {
  final String message;
  const LiveKitException._(this.message);

  @override
  String toString() => 'LiveKit Exception: [$runtimeType] $message';
}

enum ConnectionErrorReason {
  NotAllowed,
  InternalError,
  Timeout,
}

/// An exception occurred while attempting to connect.
/// Common reasons:
/// - Invalid token (make sure your token is generated correctly)
/// - Network condition is not good
/// - Server not set up correctly (not responding)
class ConnectException extends LiveKitException {
  final ConnectionErrorReason reason;
  final int statusCode;
  ConnectException(
    String msg, {
    required this.reason,
    this.statusCode = 0,
  }) : super._(msg);
}

/// An exception occurred while attempting to disconnect.
/// Common reasons:
/// - Network condition is not good.
/// - SFU deploy behind a NAT and not configured correctly.
/// - Need a turn relay server but not configured.
class MediaConnectException extends LiveKitException {
  MediaConnectException([String msg = 'Ice connection failed']) : super._(msg);
}

/// An internal state of the SDK is not correct and can not continue to execute.
/// This should not occur frequently.
class UnexpectedStateException extends LiveKitException {
  UnexpectedStateException([String msg = 'Unexpected connection state']) : super._(msg);
}

/// Exception thrown when pc negotiation fails.
class NegotiationError extends LiveKitException {
  NegotiationError([String msg = 'Negotiation Error']) : super._(msg);
}

/// Failed to create a local track.
/// Common reasons:
/// - Required permissions not yet granted to the platform.
/// - Constraints(Capture options) rejected by the platform.
class TrackCreateException extends LiveKitException {
  TrackCreateException([String msg = 'Failed to create track']) : super._(msg);
}

/// Failed to publish a local track.
/// Common reasons:
/// - Token does not have track publish permission.
/// - Network condition is not good.
class TrackPublishException extends LiveKitException {
  TrackPublishException([String msg = 'Failed to publish track']) : super._(msg);
}

/// Failed to publish data.
/// Common reasons:
/// - Token does not have data publish permission.
/// - Network condition is not good.
class DataPublishException extends LiveKitException {
  DataPublishException([String msg = 'Failed to publish data']) : super._(msg);
}

/// A certain time has passed while attempting to execute an operation.
class TimeoutException extends LiveKitException {
  TimeoutException([String msg = 'Timeout']) : super._(msg);
}

/// An exception for End to End Encryption.
class LiveKitE2EEException extends LiveKitException {
  LiveKitE2EEException([String msg = 'E2EE error']) : super._(msg);

  @override
  String toString() => 'E2EE Exception: [$runtimeType] $message';
}

class UnexpectedConnectionState extends LiveKitException {
  UnexpectedConnectionState([String msg = 'Unexpected connection state']) : super._(msg);
}
