import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _handling = false;
  bool _isFlashOn = false;
  bool _isCameraFacingFront = false;
  final _controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    if (_handling) return;

    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    setState(() => _handling = true);

    try {
      // Expect format: {Api.baseUrl}/user/<id>
      final id = raw.split('/').last;
      final res = await Api.get('/user/api/user/profile/$id');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        context.push('/scanned', extra: data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lookup failed: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller.toggleTorch();
    });
  }

  void _switchCamera() {
    setState(() {
      _isCameraFacingFront = !_isCameraFacingFront;
      _controller.switchCamera();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: "NataSans"),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(
              _isCameraFacingFront ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          _buildScannerOverlay(context),
          if (_handling)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black54 : Colors.white54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing QR code...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(0, 255, 255, 255),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
                top: 0, left: 0, child: _buildCornerIndicator(true, true)),
            Positioned(
                top: 0, right: 0, child: _buildCornerIndicator(false, true)),
            Positioned(
                bottom: 0, left: 0, child: _buildCornerIndicator(true, false)),
            Positioned(
                bottom: 0,
                right: 0,
                child: _buildCornerIndicator(false, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(bool isLeft, bool isTop) {
    return Align(
      alignment: Alignment(
        isLeft ? -1 : 1,
        isTop ? -1 : 1,
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(
                    color: const Color.fromARGB(255, 255, 255, 255), width: 4)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: const Color.fromARGB(255, 255, 255, 255), width: 4)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: const Color.fromARGB(255, 255, 255, 255), width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: const Color.fromARGB(255, 255, 255, 255), width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isLeft && isTop ? const Radius.circular(12) : Radius.zero,
            topRight:
                !isLeft && isTop ? const Radius.circular(12) : Radius.zero,
            bottomLeft:
                isLeft && !isTop ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                !isLeft && !isTop ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
