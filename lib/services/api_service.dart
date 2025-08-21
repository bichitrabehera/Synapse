import 'dart:convert';
import '../services/api.dart';

class ApiService {
  static Future<List<dynamic>> searchUsers(String query, String token) async {
    // URL encode the query parameter
    final encodedQuery = Uri.encodeComponent(query);
    final response = await Api.get('/social/search?q=$encodedQuery', headers: {
      'Authorization': 'Bearer $token',
    });
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search users: ${response.statusCode}');
    }
  }

  static Future<void> followUser(String userId, String token) async {
    final response = await Api.post('/social/follow/$userId', {}, headers: {
      'Authorization': 'Bearer $token',
    });
    
    if (response.statusCode != 200) {
      throw Exception('Failed to follow user: ${response.statusCode}');
    }
  }

  static Future<void> unfollowUser(String userId, String token) async {
    final response = await Api.delete('/social/unfollow/$userId', headers: {
      'Authorization': 'Bearer $token',
    });
    
    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user: ${response.statusCode}');
    }
  }
}
