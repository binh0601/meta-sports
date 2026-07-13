import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';
import '../widgets/brand_crest.dart';
import '../widgets/motion_effects.dart';

/// Man hinh splash dong: hien logo + ten thuong hieu roi tu chuyen sang
/// man tiep theo (login hoac sanh nguoi choi) sau ~1.8s, hoac ngay khi
/// nguoi dung cham vao man hinh.
class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final Animation<double> _crestScale = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.75, curve: Curves.elasticOut),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _titleSlide = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _shimmer = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
  );

  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), _go);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.of(context).disableAnimations) _go();
    });
  }

  void _go() {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _go,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(gradient: kBrandGradient)),
            Opacity(
              opacity: .25,
              child: Image.asset(
                'assets/images/stadium_night.jpg',
                fit: BoxFit.cover,
              ),
            ),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    Transform.scale(
                      scale: 0.6 + 0.4 * _crestScale.value,
                      child: Opacity(opacity: _fade.value, child: const BrandCrest(size: 84)),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: _titleSlide.value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _titleSlide.value)),
                        child: ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (rect) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: .35),
                              Colors.white,
                            ],
                            stops: const [0.35, 0.5, 0.65],
                            begin: Alignment(-1 + 3 * _shimmer.value, 0),
                            end: Alignment(2 + 3 * _shimmer.value, 0),
                          ).createShader(rect),
                          child: const Text(
                            'MEGA SPORTS',
                            style: TextStyle(
                              fontFamily: kDisplayFont,
                              fontSize: 34,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    const SpinningBallIcon(size: 26, color: kGold),
                    const SizedBox(height: 8),
                    const Text(
                      'CUP CHÂU Á • WORLD CUP 2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: kGold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
