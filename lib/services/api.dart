import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const String baseUrl = 'https://tapcard-backend.onrender.com/api';

  static Future<http.Response> postForm(
    String path,
    Map<String, String> body, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      ...?headers,
    };
    return http.post(uri, headers: h, body: body);
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    // Handle redirects manually to avoid 307 issues
    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(h)
        ..body = jsonEncode(data);
      
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      // Follow redirects manually
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUri = Uri.parse(response.headers['location'] ?? '');
        final redirectRequest = http.Request('POST', redirectUri)
          ..headers.addAll(h)
          ..body = jsonEncode(data);
        
        final redirectResponse = await client.send(redirectRequest);
        return await http.Response.fromStream(redirectResponse);
      }
      
      return response;
    } finally {
      client.close();
    }
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    return http.delete(uri, headers: headers);
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    final h = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    return http.put(uri, headers: h, body: jsonEncode(data));
  }
}
