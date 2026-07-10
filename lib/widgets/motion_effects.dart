import 'package:flutter/material.dart';

import '../logic/betting_math.dart';

/// Bo hieu ung chuyen dong dung chung: vao man so le (stagger),
/// nhun khi bam, so tien dem chay, icon bong xoay.

/// Truot + mo dan khi phan tu xuat hien, tre theo [index] (30-50ms/item).
class EntranceSlide extends StatefulWidget {
  final int index;
  final Widget child;
  const EntranceSlide({super.key, this.index = 0, required this.child});

  @override
  State<EntranceSlide> createState() => _EntranceSlideState();
}

class _EntranceSlideState extends State<EntranceSlide> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 12)),
        () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, .08),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Nhun nhe (scale 0.96) khi nhan xuong — phan hoi xuc giac kieu app xin.
class ScaleTap extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const ScaleTap({super.key, required this.onTap, required this.child});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// So du dem chay muot khi thay doi (thay vi nhay so kho cung).
class AnimatedMoneyText extends StatelessWidget {
  final double value; // nghin dong
  final TextStyle? style;
  const AnimatedMoneyText({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(fmtMoney(v), style: style),
    );
  }
}

/// Qua bong xoay tron lien tuc — diem nhan chuyen dong cho nut da vong.
class SpinningBallIcon extends StatefulWidget {
  final double size;
  final Color? color;
  const SpinningBallIcon({super.key, this.size = 20, this.color});

  @override
  State<SpinningBallIcon> createState() => _SpinningBallIconState();
}

class _SpinningBallIconState extends State<SpinningBallIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child:
          Icon(Icons.sports_soccer, size: widget.size, color: widget.color),
    );
  }
}
