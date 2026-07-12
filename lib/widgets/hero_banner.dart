import 'package:flutter/material.dart';

import '../logic/football_market.dart';
import '../theme/brand_colors.dart';

/// Banner anh cau thu that tren dau san keo: anh + phu gradient toi ben
/// trai de chu noi, nhan giai dau + vong hien tai. Anh va nhan doi theo
/// giai dang chon; nen zoom cham kieu Ken Burns cho song dong.
class HeroBanner extends StatelessWidget {
  final int roundNumber;
  final League league;
  const HeroBanner(
      {super.key, required this.roundNumber, required this.league});

  @override
  Widget build(BuildContext context) {
    final image = league == League.worldCup
        ? 'assets/images/action_worldcup.jpg'
        : 'assets/images/player_volley.jpg';
    return Container(
      height: 132,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _KenBurns(image: image, alignment: const Alignment(0, -.4)),
            // Phu toi tu trai sang de text doc duoc tren anh
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE60B1026), Color(0x330B1026)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(league.label,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1917))),
                  ),
                  const SizedBox(height: 8),
                  Text('Vòng $roundNumber • 8 trận hôm nay',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Odds cập nhật trực tiếp — đặt kèo trước giờ lăn bóng',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: .85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anh nen zoom cham (Ken Burns) 1.0 -> 1.08, lap vo han dao chieu, cho
/// hero banner song dong. disableAnimations (vd. test) -> anh tinh.
class _KenBurns extends StatefulWidget {
  final String image;
  final Alignment alignment;
  const _KenBurns({required this.image, required this.alignment});

  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _scale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl == null && !MediaQuery.of(context).disableAnimations) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(seconds: 9))
        ..repeat(reverse: true);
      _ctrl = ctrl;
      _scale = Tween(begin: 1.0, end: 1.08)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Widget _image(double scale) => Transform.scale(
        scale: scale,
        alignment: widget.alignment,
        child: Image.asset(widget.image,
            fit: BoxFit.cover, alignment: widget.alignment),
      );

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    if (scale == null) return _image(1.0);
    return AnimatedBuilder(
        animation: scale, builder: (_, _) => _image(scale.value));
  }
}
