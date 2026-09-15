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

import 'token_source.dart';

/// A token source that provides a fixed set of credentials without dynamic fetching.
///
/// This is useful for testing, development, or when you have pre-generated tokens
/// that don't need to be refreshed dynamically.
///
/// For dynamic token fetching, use [EndpointTokenSource] or implement [TokenSourceConfigurable].
class LiteralTokenSource implements TokenSourceFixed {
  /// The LiveKit server URL to connect to.
  final String serverUrl;

  /// The JWT token for participant authentication.
  final String participantToken;

  /// The display name for the participant (optional).
  final String? participantName;

  /// The name of the room to join (optional).
  final String? roomName;

  /// Initialize with fixed credentials.
  ///
  /// - Parameters:
  ///   - serverUrl: The LiveKit server URL to connect to
  ///   - participantToken: The JWT token for participant authentication
  ///   - participantName: The display name for the participant (optional)
  ///   - roomName: The name of the room to join (optional)
  LiteralTokenSource({
    required this.serverUrl,
    required this.participantToken,
    this.participantName,
    this.roomName,
  });

  /// Returns the fixed credentials without any network requests.
  @override
  Future<TokenSourceResponse> fetch() async {
    return TokenSourceResponse(
      serverUrl: serverUrl,
      participantToken: participantToken,
      participantName: participantName,
      roomName: roomName,
    );
  }
}
