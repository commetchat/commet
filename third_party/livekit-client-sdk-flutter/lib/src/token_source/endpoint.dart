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

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_source.dart';

/// Error thrown when the token server responds with a non-success HTTP status code.
class TokenSourceHttpException implements Exception {
  /// The endpoint that returned the error.
  final Uri uri;

  /// The HTTP status code returned by the endpoint.
  final int statusCode;

  /// The raw response body returned by the endpoint.
  final String body;

  const TokenSourceHttpException({
    required this.uri,
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() {
    return 'TokenSourceHttpException(statusCode: $statusCode, uri: $uri, body: $body)';
  }
}

/// A token source that fetches credentials via HTTP requests from a custom backend.
///
/// This implementation:
/// - Sends a POST request to the specified URL (configurable via [method])
/// - Encodes the request parameters as [TokenRequestOptions] JSON in the request body
/// - Includes any custom headers specified via [headers]
/// - Expects the response to be decoded as [TokenSourceResponse] JSON
/// - Validates HTTP status codes (200-299) and throws appropriate errors for failures
class EndpointTokenSource implements TokenSourceConfigurable {
  /// The URL endpoint for token generation.
  /// This should point to your backend service that generates LiveKit tokens.
  final Uri uri;

  /// The HTTP method to use for the token request (defaults to "POST").
  final String method;

  /// Additional HTTP headers to include with the request.
  final Map<String, String> headers;

  /// Optional HTTP client for testing purposes.
  final http.Client? client;

  /// Initialize with endpoint configuration.
  ///
  /// - [url]: The URL endpoint for token generation
  /// - [method]: The HTTP method (defaults to "POST")
  /// - [headers]: Additional HTTP headers (optional)
  /// - [client]: Custom HTTP client for testing (optional)
  EndpointTokenSource({
    required Uri url,
    this.method = 'POST',
    this.headers = const {},
    this.client,
  }) : uri = url;

  @override
  Future<TokenSourceResponse> fetch(TokenRequestOptions options) async {
    final requestBody = jsonEncode(options.toRequest().toJson());
    final requestHeaders = {
      'Content-Type': 'application/json',
      ...headers,
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    late final http.Response response;

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(requestHeaders);
      request.body = requestBody;
      final streamedResponse = await httpClient.send(request);
      response = await http.Response.fromStream(streamedResponse);
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TokenSourceHttpException(
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return TokenSourceResponse.fromJson(responseBody);
  }
}
