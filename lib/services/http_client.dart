import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpClientService {
  HttpClientService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final res = await _client.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = res.body.isEmpty ? '{}' : res.body;
      return json.decode(body) as Map<String, dynamic>;
    }
    throw HttpRequestException('Request failed (${res.statusCode})', uri: uri);
  }

  void close() => _client.close();
}

class HttpRequestException implements Exception {
  HttpRequestException(this.message, {this.uri});

  final String message;
  final Uri? uri;

  @override
  String toString() =>
      'HttpRequestException: $message${uri != null ? ' ($uri)' : ''}';
}
