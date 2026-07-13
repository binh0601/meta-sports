import 'package:flutter/material.dart';

import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
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
import 'live_score_screen.dart';

/// San keo cho NGUOI CHOI: quoc ky that, gio da, mua vang khi trung —
/// nguoi choi khong thay xac suat that va bien nha cai.
/// Dieu huong lich su / dang xuat nam o bottom nav cua PlayerHomeScreen.
class SportsbookScreen extends StatelessWidget {
  const SportsbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final wonThisRound =
            g.roundPlayed && g.lastResults.any((b) => b.won);
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
                icon: const Icon(Icons.live_tv),
                tooltip: 'Trực tiếp',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LiveScoreScreen())),
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
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              LeagueSwitcher(),
                              SizedBox(height: 8),
                              PromoBannerCarousel(),
                            ],
                          ),
                        ),
                        HeroBanner(
                            roundNumber: g.roundNumber, league: g.league),
                        for (var i = 0; i < g.matches.length; i++)
                          MatchCard(
                            key: ValueKey(g.matches[i].id),
                            match: g.matches[i],
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
