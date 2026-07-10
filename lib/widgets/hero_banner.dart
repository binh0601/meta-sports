import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';

/// Banner anh cau thu that tren dau san keo: anh + phu gradient toi ben
/// trai de chu noi, nhan giai dau + vong hien tai.
class HeroBanner extends StatelessWidget {
  final int roundNumber;
  const HeroBanner({super.key, required this.roundNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/player_volley.jpg',
                fit: BoxFit.cover, alignment: const Alignment(0, -.4)),
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
                    child: const Text('CUP CHÂU Á 2026',
                        style: TextStyle(
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
