import 'package:flutter/material.dart';

import '../logic/bet_query_filter.dart';
import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
import '../widgets/bet_finder_bar.dart';
import '../widgets/bet_slip_drawer.dart';
import '../widgets/bet_slip_panel.dart';
import '../widgets/brand_crest.dart';
import '../widgets/coin_burst.dart';
import '../widgets/gold_rain.dart';
import '../widgets/hero_banner.dart';
import '../widgets/league_switcher.dart';
import '../widgets/match_card.dart';
import '../widgets/motion_effects.dart';
import '../widgets/promo_banner_carousel.dart';

/// San keo cho NGUOI CHOI: quoc ky that, gio da, mua vang khi trung —
/// nguoi choi khong thay xac suat that va bien nha cai.
/// Dieu huong lich su / dang xuat nam o bottom nav cua PlayerHomeScreen.
class SportsbookScreen extends StatefulWidget {
  const SportsbookScreen({super.key});

  @override
  State<SportsbookScreen> createState() => _SportsbookScreenState();
}

class _SportsbookScreenState extends State<SportsbookScreen> {
  BetQueryFilter _filter = const BetQueryFilter.empty();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final wonThisRound =
            g.roundPlayed && g.lastResults.any((b) => b.won);
        final visibleMatches = _filter.isEmpty
            ? g.matches
            : g.matches
                .where((m) =>
                    _filter.matchesSide(m, true, g.league) ||
                    _filter.matchesSide(m, false, g.league))
                .toList();
        return Scaffold(
          endDrawer: const BetSlipDrawer(),
          appBar: AppBar(
            flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: kBrandGradient)),
            titleSpacing: 8,
            title: Row(
              children: [
                const BrandCrest(size: 26),
                const SizedBox(width: 8),
                const Text('MEGA SPORTS',
                    style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGold),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                      g.league == League.worldCup
                          ? 'WORLD CUP'
                          : 'CUP CHÂU Á',
                      style: const TextStyle(fontSize: 9, color: kGold)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showEdgeInfo(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _walletBar(context, g),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              const LeagueSwitcher(),
                              const SizedBox(height: 8),
                              BetFinderBar(
                                matches: g.matches,
                                filter: _filter,
                                onFilterChanged: (f) =>
                                    setState(() => _filter = f),
                              ),
                              const SizedBox(height: 8),
                              const PromoBannerCarousel(),
                            ],
                          ),
                        ),
                        HeroBanner(
                            roundNumber: g.roundNumber, league: g.league),
                        if (visibleMatches.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Không tìm thấy kèo phù hợp, thử câu hỏi khác.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        else
                          for (var i = 0; i < visibleMatches.length; i++)
                            MatchCard(
                              key: ValueKey(visibleMatches[i].id),
                              match: visibleMatches[i],
                              index: i,
                            ),
                      ],
                    ),
                  ),
                  const BetSlipPanel(),
                ],
              ),
              // Mua tien vang khi co phieu trung — remount moi vong
              if (wonThisRound)
                Positioned.fill(
                  child: GoldRainOverlay(
                      key: ValueKey('gold-rain-${g.roundNumber}')),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEdgeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Về chỉ số Edge'),
        content: const Text(
            'Edge tính từ chênh lệch giữa ước tính chuyên gia và tỷ lệ '
            'ngầm của kèo — không phải lợi nhuận thật. Biên nhà cái '
            '(~5%) vẫn luôn trừ vào kỳ vọng dài hạn, dù Edge dương hay âm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _walletBar(BuildContext context, GameState g) {
    return Container(
      decoration: const BoxDecoration(gradient: kBrandGradient),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: CoinBurst(
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 18, color: kGold),
            const SizedBox(width: 6),
            AnimatedMoneyText(
              value: g.balance,
              style: const TextStyle(
                fontFamily: kDisplayFont,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: kGold,
              ),
            ),
            const Spacer(),
            // Bam chip -> mo sidebar phieu cuoc (can Builder de lay context
            // nam duoi Scaffold)
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    g.pending.isEmpty
                        ? 'Vòng ${g.roundNumber}'
                        : 'Vòng ${g.roundNumber} • ${g.pending.length} phiếu chờ',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
