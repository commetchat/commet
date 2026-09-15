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

import 'endpoint.dart';

/// A token source that queries LiveKit's sandbox token server for development and testing.
///
/// This token source connects to LiveKit Cloud's sandbox environment, which is perfect for
/// quick prototyping and getting started with LiveKit development.
///
/// **Warning:** This token source is **insecure** and should **never** be used in production.
///
/// For production use, implement [EndpointTokenSource] with your own backend or use [CustomTokenSource].
class SandboxTokenSource extends EndpointTokenSource {
  /// Initialize with a sandbox ID from LiveKit Cloud.
  ///
  /// The [sandboxId] is obtained from your LiveKit Cloud project's sandbox settings.
  SandboxTokenSource({
    required String sandboxId,
  }) : super(
          url: Uri.parse('https://cloud-api.livekit.io/api/v2/sandbox/connection-details'),
          headers: {
            'X-Sandbox-ID': _sanitizeSandboxId(sandboxId),
          },
        );
}

String _sanitizeSandboxId(String sandboxId) {
  var sanitized = sandboxId;
  sanitized = sanitized.replaceFirst(RegExp(r'^[^a-zA-Z0-9]+'), '');
  sanitized = sanitized.replaceFirst(RegExp(r'[^a-zA-Z0-9]+$'), '');
  return sanitized;
}
