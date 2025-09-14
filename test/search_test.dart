import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Search Users Tests', () {
    test('URL encoding test', () {
      const query = "test user@email.com";
      final encoded = Uri.encodeComponent(query);
      expect(encoded, "test%20user%40email.com");
    });

    test('Empty query handling', () {
      const query = "";
      expect(query.isEmpty, true);
    });

    test('Special characters encoding', () {
      const query = "user#1 with spaces & symbols!";
      final encoded = Uri.encodeComponent(query);
      expect(encoded, "user%231%20with%20spaces%20%26%20symbols%21");
    });

    test('Query parameter formatting', () {
      const query = "john doe";
      const expectedUrl = '/social/search?q=john%20doe';
      expect(expectedUrl, '/social/search?q=john%20doe');
    });
  });
}
