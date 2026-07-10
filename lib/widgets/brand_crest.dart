import 'dart:math' as math;

import 'package:flutter/material.dart';

const _goldLight = Color(0xFFFDE68A);
const _gold = Color(0xFFF59E0B);
const _goldDark = Color(0xFFB45309);

/// Huy hieu thuong hieu kieu khien CLB: khien vang 2 lop, bong da,
/// 3 ngoi sao — ve thuan CustomPainter, khong can asset.
class BrandCrest extends StatelessWidget {
  final double size;
  const BrandCrest({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(painter: _CrestPainter()),
    );
  }
}

class _CrestPainter extends CustomPainter {
  Path _shield(Size s, double inset) {
    final w = s.width - inset * 2;
    final h = s.height - inset * 2;
    final x = inset, y = inset;
    // Khien: canh tren ngang, hong cong nhe, chum nhon duoi
    return Path()
      ..moveTo(x, y + h * .08)
      ..quadraticBezierTo(x + w * .5, y - h * .04, x + w, y + h * .08)
      ..lineTo(x + w, y + h * .52)
      ..quadraticBezierTo(x + w, y + h * .82, x + w * .5, y + h)
      ..quadraticBezierTo(x, y + h * .82, x, y + h * .52)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _shield(size, 0);
    // Vien vang ngoai + do bong phat sang
    canvas.drawShadow(outer, _gold, 10, true);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldLight, _gold, _goldDark],
        ).createShader(Offset.zero & size),
    );
    // Long khien xanh dam
    final inner = _shield(size, size.width * .07);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF0B1026)],
        ).createShader(Offset.zero & size),
    );
    // Vien chi vang mong ben trong
    canvas.drawPath(
      _shield(size, size.width * .10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .012
        ..color = _gold.withValues(alpha: .8),
    );
    // 3 ngoi sao tren dinh
    final starPaint = Paint()..color = _goldLight;
    for (var i = -1; i <= 1; i++) {
      _drawStar(
        canvas,
        Offset(size.width * (.5 + i * .17), size.height * (.22 - (i == 0 ? .035 : 0))),
        size.width * (i == 0 ? .05 : .038),
        starPaint,
      );
    }
    // Bong da: hinh tron trang + ngu giac den o giua
    final ballCenter = Offset(size.width * .5, size.height * .58);
    final ballR = size.width * .2;
    canvas.drawCircle(
      ballCenter,
      ballR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.4),
          colors: [Colors.white, Color(0xFFCBD5E1)],
        ).createShader(Rect.fromCircle(center: ballCenter, radius: ballR)),
    );
    _drawStar(canvas, ballCenter, ballR * .5, Paint()..color = const Color(0xFF1E293B),
        points: 5, rotation: -0.31);
  }

  /// Ve ngoi sao 5 canh tam [c] ban kinh [r].
  void _drawStar(Canvas canvas, Offset c, double r, Paint paint,
      {int points = 5, double rotation = -math.pi / 2}) {
    final path = Path();
    final step = math.pi * 2 / points;
    for (var i = 0; i < points; i++) {
      final a = rotation + step * i;
      final inner = a + step / 2;
      final p1 = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      final p2 = Offset(
          c.dx + r * .45 * math.cos(inner), c.dy + r * .45 * math.sin(inner));
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
