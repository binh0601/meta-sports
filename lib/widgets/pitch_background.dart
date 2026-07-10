import 'package:flutter/material.dart';

/// Nen man dang nhap: anh san van dong that lam toi + vach ke san mo
/// ben tren — tao chieu sau ma chu van doc ro.
class PitchBackground extends StatelessWidget {
  final Widget child;
  final String? imageAsset; // anh nen tuy chon (vd san van dong)
  const PitchBackground({super.key, required this.child, this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14275E), Color(0xFF070A16)],
        ),
        image: imageAsset == null
            ? null
            : DecorationImage(
                image: AssetImage(imageAsset!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: .68),
                  BlendMode.darken,
                ),
              ),
      ),
      child: CustomPaint(
        painter: _PitchLinesPainter(),
        child: child,
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: .05);

    final w = size.width;
    final h = size.height;
    // Vong tron giua san + cham giua
    canvas.drawCircle(Offset(w / 2, h / 2), w * .30, line);
    canvas.drawCircle(Offset(w / 2, h / 2), 3,
        Paint()..color = Colors.white.withValues(alpha: .06));
    // Vach giua san
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), line);
    // Vong cam dia 2 dau (nua vong tron)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, 0), radius: w * .35),
        0, 3.14159, false, line);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, h), radius: w * .35),
        3.14159, 3.14159, false, line);
    // Khung thanh 2 dau
    canvas.drawRect(
        Rect.fromLTWH(w * .25, 0, w * .5, h * .09), line);
    canvas.drawRect(
        Rect.fromLTWH(w * .25, h * .91, w * .5, h * .09), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
