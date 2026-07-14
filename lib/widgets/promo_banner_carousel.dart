import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../screens/wallet_screen.dart';
import '../theme/brand_colors.dart';

/// Bang ron khuyen mai gia — tu cuon 4s/banner cho giong app thuong mai.
/// Noi dung la moi chai khuyen mai kieu nha cai (dung chu de giao duc).
/// Bam banner -> mo man vi (tru tai khoan demo).
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _Promo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String image;
  const _Promo(this.title, this.subtitle, this.icon, this.colors, this.image);
}

const List<_Promo> _promos = [
  _Promo('NẠP LẦN ĐẦU +100%', 'Nạp 500k nhận ngay 1 triệu trong ví',
      Icons.bolt, [Color(0xFFB45309), Color(0xFF78350F)],
      'assets/images/action_stadium_flare.jpg'),
  _Promo('CƯỢC XÂU THƯỞNG KHỦNG', 'Xâu 5 kèo trở lên — thưởng thêm 30%',
      Icons.link, [Color(0xFF1D4ED8), Color(0xFF312E81)],
      'assets/images/player_volley.jpg'),
  _Promo('SIÊU KÈO CUỐI TUẦN', 'Odds tăng cực mạnh cho trận cầu tâm điểm',
      Icons.local_fire_department, [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
      'assets/images/action_worldcup.jpg'),
  _Promo('MỜI BẠN NHẬN 50K', 'Giới thiệu bạn bè — cả hai cùng có thưởng',
      Icons.card_giftcard, [Color(0xFF047857), Color(0xFF064E3B)],
      'assets/images/ball_closeup.jpg'),
];

class _PromoBannerCarouselState extends State<PromoBannerCarousel>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  AnimationController? _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _promos.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerCtrl == null && !MediaQuery.of(context).disableAnimations) {
      _shimmerCtrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _shimmerCtrl?.dispose();
    super.dispose();
  }

  void _open() {
    if (authState.isDemo) return; // demo khong co nap/rut
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WalletScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 112,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _promos.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
              final p = _promos[i];
              return GestureDetector(
                onTap: _open,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(p.image,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -.3)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                p.colors.first.withValues(alpha: .95),
                                p.colors.last.withValues(alpha: .55),
                                p.colors.last.withValues(alpha: .15),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(p.icon, size: 34, color: kGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.title,
                                        style: displayStyle(size: 15)),
                                    const SizedBox(height: 3),
                                    Text(p.subtitle,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white54),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
              ),
              if (_shimmerCtrl != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        return AnimatedBuilder(
                          animation: _shimmerCtrl!,
                          builder: (_, _) {
                            final dx = -w + _shimmerCtrl!.value * (2 * w);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Container(
                                  width: 60,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: .18),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _promos.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? kGold : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
