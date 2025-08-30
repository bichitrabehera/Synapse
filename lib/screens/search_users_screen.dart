import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _searchController.text.trim() == query) {
        _searchUsers(query);
      }
    });
  }

  // 🔹 Always refresh token
  Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Authentication required');
    return await user.getIdToken(true);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getFirebaseToken();
      final results = await ApiService.searchUsers(query, token!);
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(results);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Authentication failed. Please login again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(String userId, bool isFollowing) async {
    try {
      final token = await _getFirebaseToken();

      if (isFollowing) {
        await ApiService.unfollowUser(userId, token!);
      } else {
        await ApiService.followUser(userId, token!);
      }

      setState(() {
        final index = _searchResults.indexWhere((u) => u['id'] == userId);
        if (index != -1) _searchResults[index]['is_following'] = !isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? 'Unfollowed user' : 'Followed user'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        toolbarHeight: 10,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Network',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 37, 37, 37),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: _searchUsers,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search,
                            size: 64, color: Color.fromARGB(255, 65, 65, 65)),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search for users to connect'
                              : 'No users found for "${_searchController.text}"',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 65, 65, 65),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return UserCard(
                        user: user,
                        onFollow: () =>
                            _toggleFollow(user['id'], user['is_following']),
                        onUnfollow: () =>
                            _toggleFollow(user['id'], user['is_following']),
                        onTapProfile: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final VoidCallback onTapProfile;

  const UserCard({
    super.key,
    required this.user,
    required this.onFollow,
    required this.onUnfollow,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapProfile,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user['avatar_url'] != null
                  ? NetworkImage(user['avatar_url'])
                  : null,
              child: user['avatar_url'] == null
                  ? Text(
                      user['fullname']?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['fullname'] ?? user['username'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "@${user['username']}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: user['is_following'] ? onUnfollow : onFollow,
              style: TextButton.styleFrom(
                backgroundColor:
                    user['is_following'] ? Colors.white : Colors.blue,
                foregroundColor:
                    user['is_following'] ? Colors.black : Colors.white,
                minimumSize: const Size(80, 32),
                side: user['is_following']
                    ? const BorderSide(color: Colors.grey, width: 0.8)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                user['is_following'] ? 'Following' : 'Follow',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
