import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> socialLinks = [];
  bool loading = true;
  bool saving = false;
  String? error;

  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final List<TextEditingController> _platformControllers = [];
  final List<TextEditingController> _urlControllers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    bioController.dispose();
    for (var c in _platformControllers) {
      c.dispose();
    }
    for (var c in _urlControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final profileRes =
          await Api.get('/user/profile', headers: auth.authHeader());
      final linksRes =
          await Api.get('/user/social-links', headers: auth.authHeader());

      if (profileRes.statusCode == 200) {
        profile = jsonDecode(profileRes.body);
        userNameController.text = profile!['username'] ?? '';
        emailController.text = profile!['email'] ?? '';
        bioController.text = profile!['bio'] ?? '';
      }

      if (linksRes.statusCode == 200) {
        final responseData = jsonDecode(linksRes.body);

        socialLinks = [];
        _platformControllers.clear();
        _urlControllers.clear();

        if (responseData is List) {
          socialLinks = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map && responseData.containsKey('data')) {
          socialLinks = List<Map<String, dynamic>>.from(responseData['data']);
        }

        for (var link in socialLinks) {
          _platformControllers
              .add(TextEditingController(text: link['platform_name'] ?? ''));
          _urlControllers
              .add(TextEditingController(text: link['link_url'] ?? ''));
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void addSocialLink() {
    setState(() {
      final newLink = {'platform_name': '', 'link_url': '', 'id': ''};
      socialLinks.add(newLink);
      _platformControllers.add(TextEditingController());
      _urlControllers.add(TextEditingController());
    });
  }

  Future<void> removeSocialLink(int index) async {
    final link = socialLinks[index];
    final auth = context.read<AuthProvider>();

    if (link['id'] != null && link['id'].toString().isNotEmpty) {
      try {
        await Api.delete('/user/social-links/${link['id']}',
            headers: auth.authHeader());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }

    setState(() {
      _platformControllers[index].dispose();
      _urlControllers[index].dispose();
      _platformControllers.removeAt(index);
      _urlControllers.removeAt(index);
      socialLinks.removeAt(index);
    });
  }

  Future<void> saveAll() async {
    setState(() => saving = true);
    final auth = context.read<AuthProvider>();

    try {
      final validSocialLinks = <Map<String, dynamic>>[];
      for (var i = 0; i < socialLinks.length; i++) {
        final platform = _platformControllers[i].text.trim();
        final url = _urlControllers[i].text.trim();

        if (platform.isNotEmpty && url.isNotEmpty) {
          validSocialLinks.add({
            ...socialLinks[i],
            'platform_name': platform,
            'link_url': url,
          });
        }
      }

      // Save profile
      await Api.put(
        '/user/profile',
        {
          'username': userNameController.text.trim(),
          'email': emailController.text.trim(),
          'bio': bioController.text.trim(),
        },
        headers: auth.authHeader(),
      );

      // Save social links
      for (var i = 0; i < validSocialLinks.length; i++) {
        final link = validSocialLinks[i];
        final data = {
          'platform_name': link['platform_name'],
          'link_url': link['link_url'],
        };

        if (link['id'] != null &&
            link['id'].toString().isNotEmpty &&
            link['id'].toString() != 'null') {
          await Api.put('/user/social-links/${link['id']}', data,
              headers: auth.authHeader());
        } else {
          final res = await Api.post('/user/social-links', data,
              headers: auth.authHeader());
          if (res.statusCode == 201 || res.statusCode == 200) {
            final created = jsonDecode(res.body);
            final index = socialLinks.indexWhere((s) =>
                s['platform_name'] == link['platform_name'] &&
                s['link_url'] == link['link_url']);
            if (index != -1) socialLinks[index]['id'] = created['id'];
          }
        }
      }

      socialLinks.removeWhere((link) {
        final platform = link['platform_name']?.toString().trim() ?? '';
        final url = link['link_url']?.toString().trim() ?? '';
        return platform.isEmpty || url.isEmpty;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load profile',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton(onPressed: _load, child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: "NataSans"),
        ),
        centerTitle: true,
        actions: [
          saving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                )
              : Container(
                  margin:
                      const EdgeInsets.only(right: 12), // optional right margin
                  width: 36, // circle width
                  height: 36, // circle height
                  decoration: const BoxDecoration(
                    color: Colors.black, // background color
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 20, // icon size
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: saveAll,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0), // bottom margin
              child: Text(
                'PERSONAL INFORMATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),

            // Personal Info
            TextField(
              controller: userNameController,
              decoration: InputDecoration(
                hintText: 'Username',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                hintText: 'Bio',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Social Links
            Row(
              children: [
                Text('SOCIAL LINKS',
                    style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: colorScheme.onSurface.withOpacity(0.6))),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.add, color: colorScheme.primary),
                    onPressed: addSocialLink),
              ],
            ),
            const SizedBox(height: 8),
            if (socialLinks.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.link_off,
                        size: 28,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 4),
                    Text('No social links added',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
              )
            else
              ...socialLinks.asMap().entries.map((entry) {
                final index = entry.key;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        // Platform Field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _platformControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Platform',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            onChanged: (val) =>
                                socialLinks[index]['platform_name'] = val,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // URL Field
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _urlControllers[index],
                            decoration: InputDecoration(
                              hintText: 'URL',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            onChanged: (val) =>
                                socialLinks[index]['link_url'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Remove Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.1),
                          ),
                          child: IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => removeSocialLink(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
