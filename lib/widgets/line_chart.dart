import 'package:flutter/material.dart';

/// Mot duong du lieu tren bieu do.
class ChartSeries {
  final List<Offset> points; // (x, y) theo don vi du lieu goc
  final Color color;
  final String label;
  const ChartSeries(this.points, this.color, this.label);
}

/// Bieu do duong toi gian ve bang CustomPainter, khong can package ngoai.
class LineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final double height;
  final String Function(double)? yFormat;
  final String Function(double)? xFormat;
  final double? markX; // ve vach doc danh dau (vd: n = 361)
  final String? markLabel;

  const LineChart({
    super.key,
    required this.series,
    this.height = 220,
    this.yFormat,
    this.xFormat,
    this.markX,
    this.markLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              series: series,
              yFormat: yFormat ?? (v) => v.toStringAsFixed(0),
              xFormat: xFormat ?? (v) => v.toStringAsFixed(0),
              markX: markX,
              markLabel: markLabel,
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              gridColor: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            for (final s in series.where((s) => s.label.isNotEmpty))
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 3, color: s.color),
                const SizedBox(width: 4),
                Text(s.label, style: Theme.of(context).textTheme.bodySmall),
              ]),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final String Function(double) yFormat;
  final String Function(double) xFormat;
  final double? markX;
  final String? markLabel;
  final Color textColor;
  final Color gridColor;

  _LineChartPainter({
    required this.series,
    required this.yFormat,
    required this.xFormat,
    required this.textColor,
    required this.gridColor,
    this.markX,
    this.markLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final all = series.expand((s) => s.points).toList();
    if (all.isEmpty) return;
    var minX = all.first.dx, maxX = all.first.dx;
    var minY = 0.0, maxY = 0.0;
    for (final p in all) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    if (maxX == minX) maxX = minX + 1;
    if (maxY == minY) maxY = minY + 1;

    const padLeft = 48.0, padBottom = 20.0, padTop = 6.0, padRight = 6.0;
    final w = size.width - padLeft - padRight;
    final h = size.height - padBottom - padTop;
    Offset map(Offset p) => Offset(
          padLeft + (p.dx - minX) / (maxX - minX) * w,
          padTop + h - (p.dy - minY) / (maxY - minY) * h,
        );

    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.7;
    // Luoi ngang + nhan truc Y
    for (var i = 0; i <= 4; i++) {
      final yVal = minY + (maxY - minY) * i / 4;
      final y = map(Offset(minX, yVal)).dy;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), grid);
      _text(canvas, yFormat(yVal), Offset(0, y - 6), 9);
    }
    // Nhan truc X (3 moc)
    for (var i = 0; i <= 2; i++) {
      final xVal = minX + (maxX - minX) * i / 2;
      final x = map(Offset(xVal, minY)).dx;
      _text(canvas, xFormat(xVal), Offset(x - 12, size.height - 14), 9);
    }
    // Vach danh dau (vd n = 361)
    if (markX != null && markX! >= minX && markX! <= maxX) {
      final x = map(Offset(markX!, minY)).dx;
      final markPaint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, padTop), Offset(x, padTop + h), markPaint);
      if (markLabel != null) {
        _text(canvas, markLabel!, Offset(x + 4, padTop), 10, Colors.amber);
      }
    }
    // Cac duong du lieu
    for (final s in series) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(map(s.points.first).dx, map(s.points.first).dy);
      for (final p in s.points.skip(1)) {
        final m = map(p);
        path.lineTo(m.dx, m.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _text(Canvas canvas, String text, Offset at, double fontSize,
      [Color? color]) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color ?? textColor, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.series != series || old.markX != markX;
}
