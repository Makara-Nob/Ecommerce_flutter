import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MEASUREMENTS derived directly from KHQR_-_digital_payment.svg
//
//  SVG card rect : x=21, y=21  →  x=421, y=601  (400 × 580 px)
//  Header path   : M21 21 H421 V123.5 L388.1,90.6 H21 V21 Z
//    left-side height  = 90.6 − 21  =  69.6 px  → ratio 0.6790
//    right-side height = 123.5 − 21 = 102.5 px  → full height of clipper
//    chamfer x         = 388.1 − 21 = 367.1 px  → ratio 0.9178 of card width
//  Dashed divider: y = 218.5 (SVG) → 197.5 px from card top
//  QR area starts: y = 267   (SVG) → 246   px from card top
// ─────────────────────────────────────────────────────────────────────────────

// ── Isolated timer — only this widget rebuilds every second ──────────────────
class _CountdownBadge extends StatefulWidget {
  final int initialSeconds;
  const _CountdownBadge({required this.initialSeconds});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  late Timer _timer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _fmt {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _color {
    if (_secondsLeft > 120) return const Color(0xFF00C853);
    if (_secondsLeft > 60) return const Color(0xFFFF9100);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.08 + _pulse.value * 0.06),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _color.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: _color),
            const SizedBox(width: 5),
            Text(
              _fmt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Clipper — matches SVG path exactly ────────────────────────────────
//
//  SVG header: M21 21 H421 V123.5 L388.1,90.6 H21 V21 Z
//  Translated to local coords (card starts at 0,0):
//    chamfer x ratio   = (388.1 − 21) / (421 − 21) = 367.1 / 400 = 0.91775
//    left height ratio = (90.6  − 21) / (123.5 − 21) = 69.6 / 102.5 = 0.67902
// ─────────────────────────────────────────────────────────────────────────────
class _KhqrHeaderClipper extends CustomClipper<Path> {
  static const double _chamferXRatio = 367.1 / 400;    // 0.91775
  static const double _leftHeightRatio = 69.6 / 102.5; // 0.67902

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * _chamferXRatio, size.height * _leftHeightRatio)
      ..lineTo(0, size.height * _leftHeightRatio)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── Dashed line — matches SVG stroke-dasharray="8 8", stroke-opacity="0.5" ───
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, 0), paint);
      x += 16; // 8 dash + 8 gap
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class AbaKhqrScreen extends StatefulWidget {
  final String qrImage;
  final String qrString;
  final String amount;
  final String tranId;
  final Future<bool> Function({bool silent}) onVerify; // ➕ Returns bool: true = confirmed
  final String merchantName;

  const AbaKhqrScreen({
    super.key,
    required this.qrImage,
    required this.qrString,
    required this.amount,
    required this.tranId,
    required this.onVerify,
    this.merchantName = 'NAGA',
  });

  @override
  State<AbaKhqrScreen> createState() => _AbaKhqrScreenState();
}

class _AbaKhqrScreenState extends State<AbaKhqrScreen> {
  Timer? _pollingTimer;
  Uint8List? _imageBytes;
  bool _paymentConfirmed = false; // ➕ NEW — guard to stop duplicate polls

  @override
  void initState() {
    super.initState();

    // Decode base64 QR image safely
    try {
      if (widget.qrImage.isNotEmpty) {
        final String clean = widget.qrImage.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
        _imageBytes = Uint8List.fromList(base64Decode(clean));
      } else {
        _imageBytes = null; // Trigger mock
      }
    } catch (e) {
      debugPrint('Error decoding QR base64: $e');
      _imageBytes = null; // Trigger mock on error
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // ➕ Stop polling once confirmed, prevents redundant calls after navigation
      if (_paymentConfirmed) return;
      final confirmed = await widget.onVerify(silent: true);
      if (confirmed && mounted) {
        _paymentConfirmed = true;
        _pollingTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: _CountdownBadge(initialSeconds: 180),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _KhqrCard(
              amount: widget.amount,
              imageBytes: _imageBytes,
              merchantName: widget.merchantName, // ➕ NEW — pass merchant name down
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.04, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saving QR to gallery...')),
                  );
                },
                icon: const Icon(Icons.download_rounded,
                    color: Color(0xFF00B4DB), size: 20),
                label: const Text(
                  'Download QR',
                  style: TextStyle(
                    color: Color(0xFF00B4DB),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ],
          ),
        ),
      ),
    );
  }
}

// ── Card widget — pure presentation, stateless ───────────────────────────────
// Kept separate so the parent screen never rebuilds this due to timer ticks.
class _KhqrCard extends StatelessWidget {
  final String amount;
  final Uint8List? imageBytes;
  final String merchantName; // ➕ NEW — display the real merchant name

  const _KhqrCard({
    required this.amount,
    required this.imageBytes,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── RED HEADER ──────────────────────────────────────────────────────
          ClipPath(
            clipper: _KhqrHeaderClipper(),
            child: Container(
              height: 105,
              color: const Color(0xFFE21A1A),
              // Logo sits in the left-height zone (105 × 0.679 ≈ 71px tall)
              padding: EdgeInsets.only(bottom: 105 * (1 - 0.679)),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/khqr/KHQR_Logo.png',
                height: 26,
                color: Colors.white, // Tint to ensure it's white on the red background
              ),
            ),
          ),

          // ── AMOUNT ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName, // ➕ NEW — was hardcoded 'Company Name'
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      amount, // ← StatelessWidget field, NOT widget.amount
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'USD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── DASHED DIVIDER ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 1,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),

          // ── QR CODE ─────────────────────────────────────────────────────────
          Padding(
             padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
             child: imageBytes != null
                 ? Image.memory(
                     imageBytes!,
                     width: double.infinity,
                     fit: BoxFit.contain,
                   )
                 : const Center(
                     child: Icon(
                       Icons.qr_code_2_rounded,
                       size: 200,
                       color: Colors.black12,
                     ),
                   ),
          ),
        ],
      ),
      ));
  }
}