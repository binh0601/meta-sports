import 'dart:math';

import 'package:flutter/material.dart';

/// Hieu ung mua tien vang khi trung phieu: ~36 dong xu roi tu tren xuong,
/// lac lu nhe theo chieu ngang, mo dan roi tu bien mat. Chay 1 lan (~2.8s).
class GoldRainOverlay extends StatefulWidget {
  const GoldRainOverlay({super.key});

  @override
  State<GoldRainOverlay> createState() => _GoldRainOverlayState();
}

class _Coin {
  final double x; // vi tri ngang (0..1)
  final double delay; // tre truoc khi roi (0..0.4)
  final double size;
  final double sway; // bien do lac ngang
  final double spin; // pha xoay de dong xu "lat"
  _Coin(Random rng)
      : x = rng.nextDouble(),
        delay = rng.nextDouble() * .4,
        size = 10 + rng.nextDouble() * 14,
        sway = (rng.nextDouble() - .5) * 60,
        spin = rng.nextDouble() * pi * 2;
}

class _GoldRainOverlayState extends State<GoldRainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Coin> _coins;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _coins = List.generate(36, (_) => _Coin(Random()));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward().whenComplete(() => setState(() => _done = true));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _GoldRainPainter(_coins, _ctrl.value),
        ),
      ),
    );
  }
}

class _GoldRainPainter extends CustomPainter {
  final List<_Coin> coins;
  final double t;
  _GoldRainPainter(this.coins, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in coins) {
      final p = ((t - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (p == 0) continue;
      final opacity = p > .8 ? (1 - p) / .2 : 1.0;
      final dx = c.x * size.width + sin(p * pi * 3 + c.spin) * c.sway;
      final dy = -30 + p * (size.height + 60);
      // Dong xu "lat" bang cach co gian chieu ngang theo pha xoay
      final squash = (cos(p * pi * 6 + c.spin)).abs().clamp(.25, 1.0);
      final rect = Rect.fromCenter(
          center: Offset(dx, dy),
          width: c.size * squash,
          height: c.size);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.4),
            colors: [
              const Color(0xFFFDE68A).withValues(alpha: opacity),
              const Color(0xFFF59E0B).withValues(alpha: opacity),
              const Color(0xFFB45309).withValues(alpha: opacity),
            ],
          ).createShader(rect),
      );
      // Vien ngoai dam cho khoi hinh
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF92400E).withValues(alpha: opacity * .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldRainPainter old) => old.t != t;
}
