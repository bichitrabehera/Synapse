import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';
import 'package:tapapp_flutter/widgets/Loader.dart';

import '../providers/auth_provider.dart';
import '../services/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;

  final GlobalKey _qrKey = GlobalKey(); // for QR capture

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final res =
          await Api.get('/user/profile', headers: await auth.authHeader());
      if (res.statusCode == 200) {
        profile = jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        error = 'Failed to load profile: ${res.statusCode}';
        context.read<AuthProvider>().logout(context);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (loading) return const Center(child: JumpingLoader());
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Synapse')),
        body: Center(
          child: Text(
            error!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }
    if (profile == null) return const SizedBox.shrink();

    final id = profile!['id'] ?? profile!['user_id'] ?? '';
    final username = profile!['username'] ?? '';
    final qrValue = 'https://synapseeee.vercel.app/u/$id';

    return Scaffold(
      backgroundColor:
          isDarkMode ? Colors.grey[900] : const ui.Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Synapse',
          style: TextStyle(
            fontFamily: "Cursive",
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: isDarkMode
                ? Colors.white
                : const ui.Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Greeting
            Text(
              'Hello @$username',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Instruction
            Text(
              'Scan to connect',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),

            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: qrValue,
                  version: QrVersions.auto,
                  size: MediaQuery.of(context).size.width * 0.6,
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.white,
                  ),
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: const ui.Color.fromRGBO(0, 96, 250, 1),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 8),
            Text(
              'Your Digital Identity',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 40),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const ui.Color.fromRGBO(0, 96, 250, 1),
                  foregroundColor: const ui.Color.fromARGB(255, 255, 255, 255), // Icon & text color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // fully rounded
                  ),
                ),
                onPressed: () =>
                    Share.share('Connect with me on Synapse: $qrValue'),
                icon: const Icon(Icons.share, size: 20),
                label: const Text(
                  'Share QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
