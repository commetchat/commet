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

/// Function signature for custom token generation logic.
typedef CustomTokenFunction = Future<TokenSourceResponse> Function(TokenRequestOptions options);

/// A custom token source that executes provided logic to fetch credentials.
///
/// This allows you to implement your own token fetching strategy with full control
/// over how credentials are generated or retrieved.
class CustomTokenSource implements TokenSourceConfigurable {
  final CustomTokenFunction _function;

  /// Initialize with a custom token generation function.
  ///
  /// The [function] will be called whenever credentials need to be fetched,
  /// receiving [TokenRequestOptions] and returning a [TokenSourceResponse].
  CustomTokenSource(CustomTokenFunction function) : _function = function;

  @override
  Future<TokenSourceResponse> fetch(TokenRequestOptions options) async => _function(options);
}
