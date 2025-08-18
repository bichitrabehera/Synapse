import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final p = await Api.get('/user/profile', headers: auth.authHeader());

      if (p.statusCode == 200) {
        profile = jsonDecode(p.body);

        if (profile != null && profile!['social_links'] != null) {
          links = List<dynamic>.from(profile!['social_links']);
        } else {
          final l =
              await Api.get('/user/social-links', headers: auth.authHeader());
          if (l.statusCode == 200) {
            final responseData = jsonDecode(l.body);
            if (responseData is List) {
              links = responseData;
            } else if (responseData is Map &&
                responseData.containsKey('data')) {
              links = responseData['data'];
            }
          }
        }
      }

      links = links
          .where((link) =>
              link != null &&
              link['platform_name'] != null &&
              link['link_url'] != null &&
              link['platform_name'].toString().isNotEmpty &&
              link['link_url'].toString().isNotEmpty)
          .toList();

      error = null;
    } catch (e) {
      error = e.toString();
      links = [];
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
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
    final auth = context.read<AuthProvider>();

    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const JumpingLoader(),
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
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: "NataSans"),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        width:
            MediaQuery.of(context).size.width * 0.6, // slimmer (60% of screen)
        backgroundColor: Colors.white, // white bg
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(1),
            bottomLeft: Radius.circular(1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 30, left: 16, right: 16), // top space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Settings Heading ----
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: "NataSans",
                    ),
                  ),
                ),

                // ---- Edit Profile ----
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/edit');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: const [
                        Icon(Icons.edit, color: Colors.black, size: 22),
                        SizedBox(width: 12),
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // ---- Logout ----
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    auth.logout(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: Colors.red, size: 22),
                        SizedBox(width: 12),
                        Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---- Avatar ----
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
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
                      transform: GradientRotation(295 * 3.1416 / 180),
                      colors: [
                        Color.fromRGBO(9, 91, 168, 1),
                        Color.fromRGBO(13, 49, 150, 1),
                      ],
                      stops: [0.41, 1.0],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '@${profile!['username']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile!['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: Colors.black.withOpacity(0.6)),
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

              // ---- Social links ----
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
                            borderRadius: BorderRadius.circular(8),
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
                              style: const TextStyle(color: Colors.black),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.black),
                            onTap: () => _launchUrl(link['link_url']),
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
