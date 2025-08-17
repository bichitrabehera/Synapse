// Add imports
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

  // Controllers
  final fullNameController = TextEditingController();
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
    fullNameController.dispose();
    emailController.dispose();
    bioController.dispose();
    for (var c in _platformControllers) c.dispose();
    for (var c in _urlControllers) c.dispose();
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
        fullNameController.text = profile!['full_name'] ?? '';
        emailController.text = profile!['email'] ?? '';
        bioController.text = profile!['bio'] ?? '';
      }

      if (linksRes.statusCode == 200) {
        socialLinks =
            List<Map<String, dynamic>>.from(jsonDecode(linksRes.body));

        _platformControllers.clear();
        _urlControllers.clear();

        for (var link in socialLinks) {
          _platformControllers
              .add(TextEditingController(text: link['platform_name']));
          _urlControllers.add(TextEditingController(text: link['link_url']));
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
      final newLink = {'platform_name': '', 'link_url': '', 'id': null};
      socialLinks.add(newLink);
      _platformControllers.add(TextEditingController());
      _urlControllers.add(TextEditingController());
    });
  }

  Future<void> removeSocialLink(int index) async {
    final link = socialLinks[index];
    final auth = context.read<AuthProvider>();

    if (link['id'] != null) {
      // Delete from server
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

    // Remove locally
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
      // Save profile
      await Api.put(
        '/user/profile',
        {
          'full_name': fullNameController.text,
          'email': emailController.text,
          'bio': bioController.text,
        },
        headers: auth.authHeader(),
      );

      // Save social links
      for (var i = 0; i < socialLinks.length; i++) {
        final link = socialLinks[i];
        final data = {
          'platform_name': _platformControllers[i].text,
          'link_url': _urlControllers[i].text,
        };

        if ((link['id'] ?? '') != '') {
          // Update existing
          await Api.put('/user/social-links/${link['id']}', data,
              headers: auth.authHeader());
        } else {
          // Create new and capture response
          final res = await Api.post('/user/social-links', data,
              headers: auth.authHeader());
          if (res.statusCode == 201 || res.statusCode == 200) {
            final created = jsonDecode(res.body);
            socialLinks[i]['id'] = created['id']; // store new ID
          }
        }
      }

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
        title: const Text('Edit Profile'),
        actions: [
          saving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : IconButton(icon: const Icon(Icons.check), onPressed: saveAll),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROFILE INFORMATION',
                style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(
                controller: bioController,
                decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true),
                maxLines: 3),
            const SizedBox(height: 32),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.link_off,
                        size: 32,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text('No social links added',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
              )
            else
              ...socialLinks.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _platformControllers[index],
                              decoration: InputDecoration(
                                  labelText: 'Platform',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onChanged: (val) =>
                                  socialLinks[index]['platform_name'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                              icon: Icon(Icons.close, color: colorScheme.error),
                              onPressed: () => removeSocialLink(index)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _urlControllers[index],
                        decoration: InputDecoration(
                            labelText: 'Link URL',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onChanged: (val) =>
                            socialLinks[index]['link_url'] = val,
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
