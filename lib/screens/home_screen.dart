import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
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
      final res = await Api.get('/user/profile', headers: auth.authHeader());
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

  Future<void> _downloadQr() async {
    try {
      // ✅ Ask for storage permission first
      var status = await Permission.storage.request();

      if (status.isGranted) {
        // continue with your logic
      } else if (status.isDenied) {
        // ❌ User denied
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied ❌')),
        );
        return;
      } else if (status.isPermanentlyDenied) {
        // ⚠️ User permanently denied → open app settings
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Permission permanently denied. Enable it in settings ⚙️'),
          ),
        );
        openAppSettings();
        return;
      }

      // ----- Proceed only if permission granted -----
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save temporarily first
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Save to gallery using MediaStore
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: file.path, // <-- path to your saved file
        dirType: DirType.download, // <-- still works for images
        dirName: DirName.pictures, // <-- goes into Pictures
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code saved to Gallery ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (loading) return Center(child: JumpingLoader());
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
    final qrValue = '${Api.baseUrl}/user/$id';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const ui.Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Synapse',
          style: TextStyle(
            fontFamily: 'Cursive',
            // fontFamily: "NataSans",
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: ui.Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,
                color: Color.fromARGB(255, 255, 0, 0), size: 24),
            onPressed: () => auth.logout(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const ui.Color.fromARGB(255, 255, 255, 255),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Your Digital Identity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan this QR code to connect with others',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // QR Card
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.colorScheme.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (!isDarkMode)
                      BoxShadow(
                        color: const ui.Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue,
                          width: 2, // blue border
                        ),
                      ),
                      child: RepaintBoundary(
                        key: _qrKey,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QrImageView(
                              data: qrValue,
                              version: QrVersions.auto,
                              size: 160,
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape:
                                    QrDataModuleShape.circle, // ⬅ dotted style
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '@${profile!['username'] ?? ''}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? theme.colorScheme.surfaceVariant
                    : const ui.Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEMBER SINCE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile!['created_at'] != null
                            ? DateFormat('MMMM yyyy')
                                .format(DateTime.parse(profile!['created_at']))
                            : 'N/A',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'YOUR ID',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        id.substring(0, 8).toUpperCase(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        Share.share('Connect with me on Synapse: $qrValue'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Share QR Code',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    onPressed: _downloadQr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Save QR',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
