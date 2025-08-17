import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api.dart';
import 'package:tapapp_flutter/widgets/Loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  List<dynamic> links = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final p = await Api.get('/user/profile', headers: auth.authHeader());
      final l =
          await Api.get('/user/social-links/', headers: auth.authHeader());
      if (p.statusCode == 200) profile = jsonDecode(p.body);
      if (l.statusCode == 200) links = jsonDecode(l.body);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'linkedin':
        return Icons.linked_camera;
      case 'github':
        return Icons.code;
      case 'youtube':
        return Icons.play_circle_filled;
      case 'website':
        return Icons.public;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const JumpingLoader(), // <-- your loader here
              const SizedBox(height: 16),
              Text(
                'Loading your profile',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Could not load profile',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 24),
                FilledButton(onPressed: _load, child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      );
    }

    if (profile == null) return const SizedBox.shrink();

    final joinedDate = profile!['created_at'] != null
        ? DateFormat.yMMM().format(DateTime.parse(profile!['created_at']))
        : 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true, // ← This is the key property
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: "NataSans"
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () => context.push('/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // WorldApp-style blue neon avatar
              Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(
                            295 * 3.1416 / 180), // rotate 295deg
                        colors: [
                          Color.fromRGBO(9, 91, 168, 1), // rgba(22,19,70,1)
                          Color.fromRGBO(13, 49, 150, 1), // rgba(89,177,237,1)
                        ],
                        stops: [0.41, 1.0], // match CSS 41% and 100%
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              // Username
              Text(
                '@${profile!['username']}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Email
              Text(
                profile!['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              // Bio
              if (profile!['bio'] != null && profile!['bio'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    profile!['bio'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Divider(color: Colors.black.withOpacity(0.1)),
              const SizedBox(height: 16),
              // Joined Date
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined $joinedDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Social Links
              if (links.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONNECT',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...links.map((link) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.blueAccent.withOpacity(0.1),
                              child: Icon(
                                _getPlatformIcon(link['platform_name']),
                                color: Colors.blueAccent,
                              ),
                            ),
                            title: Text(
                              link['platform_name'] ?? 'Social Link',
                              style: TextStyle(color: Colors.black),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.black,
                            ),
                            onTap: () {},
                          ),
                        )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
