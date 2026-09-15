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

import 'dart:async';

import 'package:json_annotation/json_annotation.dart';

import '../support/reusable_completer.dart';
import 'jwt.dart';
import 'token_source.dart';

part 'caching.g.dart';

/// A validator function that determines if cached credentials are still valid.
///
/// The validator receives the original request options and cached response, and should
/// return `true` if the cached credentials are still valid for the given request.
///
/// The default validator checks JWT expiration using [isResponseExpired].
typedef TokenValidator = bool Function(TokenRequestOptions options, TokenSourceResponse response);

/// A tuple containing the request options and response that were cached.
@JsonSerializable()
class TokenStoreItem {
  final TokenRequestOptions options;
  final TokenSourceResponse response;

  const TokenStoreItem({
    required this.options,
    required this.response,
  });

  factory TokenStoreItem.fromJson(Map<String, dynamic> json) => _$TokenStoreItemFromJson(json);
  Map<String, dynamic> toJson() => _$TokenStoreItemToJson(this);
}

/// Protocol for storing and retrieving cached token credentials.
///
/// Implement this abstract class to create custom storage solutions like
/// SharedPreferences or secure storage for token caching.
abstract class TokenStore {
  /// Store credentials in the store.
  ///
  /// This replaces any existing cached credentials with the new ones.
  Future<void> store(TokenRequestOptions options, TokenSourceResponse response);

  /// Retrieve the cached credentials.
  ///
  /// Returns the cached credentials if found, null otherwise.
  Future<TokenStoreItem?> retrieve();

  /// Clear all stored credentials.
  Future<void> clear();
}

/// A simple in-memory store implementation for token caching.
///
/// This store keeps credentials in memory and is lost when the app is terminated.
/// Suitable for development and testing.
class InMemoryTokenStore implements TokenStore {
  TokenStoreItem? _cached;

  @override
  Future<void> store(TokenRequestOptions options, TokenSourceResponse response) async {
    _cached = TokenStoreItem(options: options, response: response);
  }

  @override
  Future<TokenStoreItem?> retrieve() async {
    return _cached;
  }

  @override
  Future<void> clear() async {
    _cached = null;
  }
}

/// Default validator that checks JWT expiration using [isResponseExpired].
bool _defaultValidator(TokenRequestOptions options, TokenSourceResponse response) {
  return !isResponseExpired(response);
}

/// A token source that caches credentials from any [TokenSourceConfigurable] using a configurable store.
///
/// This wrapper improves performance by avoiding redundant token requests when credentials are still valid.
/// It automatically validates cached tokens and fetches new ones when needed.
///
/// The cache will refetch credentials when:
/// - The cached token has expired (validated via [TokenValidator])
/// - The request options have changed
/// - The cache has been explicitly invalidated via [invalidate]
class CachingTokenSource implements TokenSourceConfigurable {
  final TokenSourceConfigurable _wrapped;
  final TokenStore _store;
  final TokenValidator _validator;
  final Map<TokenRequestOptions, ReusableCompleter<TokenSourceResponse>> _inflightRequests = {};

  /// Initialize a caching wrapper around any token source.
  ///
  /// - Parameters:
  ///   - wrapped: The underlying token source to wrap and cache
  ///   - store: The store implementation to use for caching (defaults to in-memory store)
  ///   - validator: A function to determine if cached credentials are still valid (defaults to JWT expiration check)
  CachingTokenSource(
    this._wrapped, {
    TokenStore? store,
    TokenValidator? validator,
  })  : _store = store ?? InMemoryTokenStore(),
        _validator = validator ?? _defaultValidator;

  @override
  Future<TokenSourceResponse> fetch(TokenRequestOptions options) async {
    final existingCompleter = _inflightRequests[options];
    if (existingCompleter != null && existingCompleter.isActive) {
      return existingCompleter.future;
    }

    final completer = existingCompleter ?? ReusableCompleter<TokenSourceResponse>();
    _inflightRequests[options] = completer;
    final resultFuture = completer.future;

    try {
      final cached = await _store.retrieve();
      if (cached != null && cached.options == options && _validator(cached.options, cached.response)) {
        completer.complete(cached.response);
        return resultFuture;
      }

      final response = await _wrapped.fetch(options);
      await _store.store(options, response);
      completer.complete(response);
      return resultFuture;
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      _inflightRequests.remove(options);
    }
  }

  /// Invalidate the cached credentials, forcing a fresh fetch on the next request.
  Future<void> invalidate() async {
    await _store.clear();
  }

  /// Get the cached credentials if one exists.
  Future<TokenSourceResponse?> cachedResponse() async {
    final cached = await _store.retrieve();
    return cached?.response;
  }
}

/// Extension to add caching capabilities to any [TokenSourceConfigurable].
extension CachedTokenSource on TokenSourceConfigurable {
  /// Wraps this token source with caching capabilities.
  ///
  /// The returned token source will reuse valid tokens and only fetch new ones when needed.
  ///
  /// - Parameters:
  ///   - store: The store implementation to use for caching (defaults to in-memory store)
  ///   - validator: A function to determine if cached credentials are still valid (defaults to JWT expiration check)
  /// - Returns: A caching token source that wraps this token source
  CachingTokenSource cached({
    TokenStore? store,
    TokenValidator? validator,
  }) =>
      CachingTokenSource(
        this,
        store: store,
        validator: validator,
      );
}
