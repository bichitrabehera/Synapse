import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannedProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ScannedProfileScreen({super.key, this.data});

  @override
  State<ScannedProfileScreen> createState() => _ScannedProfileScreenState();
}

class _ScannedProfileScreenState extends State<ScannedProfileScreen> {
  late Map<String, dynamic>? map;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    map = widget.data;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: get data from route arguments if not passed directly
    map ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (map == null) {
      return const Scaffold(
        body: Center(child: Text('No data available')),
      );
    }

    final fullname = map!['full'] ?? 'user';
    final username = map!['username'] ?? 'user';
    final bio = map!['bio'] ?? '';
    final socialLinks =
        map!['social_links'] is List ? map!['social_links'] as List : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: "NataSans",
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              backgroundImage: map!['avatar_url'] != null
                  ? NetworkImage(map!['avatar_url'])
                  : null,
              child: map!['avatar_url'] == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '$fullname',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            // Username
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Follow / Unfollow button
            SizedBox(
              width: 140,
              child: TextButton(
                onPressed: () {
                  setState(() => isFollowing = !isFollowing);
                },
                style: TextButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.white : Colors.blue,
                  foregroundColor: isFollowing ? Colors.black : Colors.white,
                  side: isFollowing
                      ? const BorderSide(color: Colors.grey, width: 0.8)
                      : BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            if (bio.isNotEmpty)
              Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),

            // Social Links
            if (socialLinks.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 16),
              ...socialLinks.map((link) {
                final platform = link['platform_name'] ?? 'Social Link';
                final url = link['link_url'] ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _getPlatformIcon(platform),
                    color: Colors.black54,
                  ),
                  title: Text(
                    platform,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    url,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.black26,
                  ),
                  onTap: () => _launchUrl(url),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    platform = platform.toLowerCase();
    switch (platform) {
      case 'facebook':
        return Icons.facebook;
      case 'linkedin':
        return Icons.work_outline;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.link;
    }
  }
}
