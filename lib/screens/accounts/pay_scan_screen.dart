import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/prosacco_palette.dart';

/// Scan a merchant / till QR for payment (Till, PayBill, etc.).
class PayScanScreen extends StatefulWidget {
  const PayScanScreen({super.key});

  @override
  State<PayScanScreen> createState() => _PayScanScreenState();
}

class _PayScanScreenState extends State<PayScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw =
        cap.barcodes.isEmpty ? null : cap.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    _controller.stop();
    if (!mounted) return;
    final p = context.pal;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR captured', style: TextStyle(color: p.headlineGreen)),
        content: SelectableText(
          raw,
          style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _handled = false);
              _controller.start();
            },
            child: const Text('Scan again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment flow for this QR will open when checkout is wired.',
                  ),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan to pay'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, err) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Camera unavailable: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                color: p.primary.withValues(alpha: 0.6),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Align the QR code within the frame. Lighting helps the camera focus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: size.width * 0.72,
        height: size.width * 0.72,
      ),
      const Radius.circular(16),
    );
    final path = Path()..addRect(Offset.zero & size);
    final cutPath = Path()..addRRect(cut);
    final overlay = Path.combine(PathOperation.difference, path, cutPath);
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(cut, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
