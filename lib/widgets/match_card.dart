import 'package:flutter/material.dart';

import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../screens/match_detail_screen.dart';
import '../theme/brand_colors.dart';
import 'motion_effects.dart';

/// The tran dau tren san keo: quoc ky that, gio da, 2 nut odds.
/// Vao man co hieu ung truot so le; bam the nhun nhe roi mo chi tiet tran.
class MatchCard extends StatelessWidget {
  final FootballMatch match;
  final int index; // thu tu trong danh sach, dung cho stagger entrance
  const MatchCard({super.key, required this.match, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return EntranceSlide(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: match.played
                ? const [Color(0xFF262B3D), Color(0xFF171923)]
                : const [Color(0xFF1E2749), Color(0xFF141A33)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -14,
                child: Icon(Icons.sports_soccer,
                    size: 96, color: Colors.white.withValues(alpha: .045)),
              ),
              ScaleTap(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(match: match)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child:
                                  _team(match.home, match.flagHome, false)),
                          _centerBadge(context),
                          Expanded(
                              child: _team(match.away, match.flagAway, true)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: OddsSelectButton(
                                  match: match, onHome: true)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('VS',
                                style: displayStyle(
                                    size: 12,
                                    color: kGold.withValues(alpha: .8))),
                          ),
                          Expanded(
                              child: OddsSelectButton(
                                  match: match, onHome: false)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Chấp',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: .5))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: OddsSelectButton(
                                  match: match,
                                  onHome: true,
                                  market: MarketType.handicap)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: OddsSelectButton(
                                  match: match,
                                  onHome: false,
                                  market: MarketType.handicap)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Xem nhận định & phong độ ›',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ten doi + quoc ky; [reverse] cho doi khach (co nam ben phai).
  Widget _team(String name, String flag, bool reverse) {
    final flagImg = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(flag, width: 34, height: 23, fit: BoxFit.cover),
      ),
    );
    final label = Expanded(
      child: Text(
        name,
        textAlign: reverse ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
    return Row(
      children: reverse
          ? [label, const SizedBox(width: 8), flagImg]
          : [flagImg, const SizedBox(width: 8), label],
    );
  }

  /// Chip giua: gio da (chua da) hoac ty so (da xong).
  Widget _centerBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: match.played ? scheme.primaryContainer : null,
              gradient: match.played
                  ? null
                  : LinearGradient(
                      colors: [
                        const Color(0xFF1D4ED8).withValues(alpha: .35),
                        const Color(0xFF0B1026).withValues(alpha: .35),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              match.score,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: match.played
                    ? scheme.onPrimaryContainer
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          match.played
              ? const Text(
                  'KẾT THÚC',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: Colors.lightGreen),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    PulseDot(Colors.lightGreen),
                    SizedBox(width: 4),
                    Text(
                      'MỞ CƯỢC',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: Colors.lightGreen),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

/// Nut chon cua cuoc — dung o ca MatchCard va man chi tiet tran.
class OddsSelectButton extends StatelessWidget {
  final FootballMatch match;
  final bool onHome;
  final MarketType market;
  const OddsSelectButton(
      {super.key,
      required this.match,
      required this.onHome,
      this.market = MarketType.match1x2});

  @override
  Widget build(BuildContext context) {
    final g = gameState;
    final scheme = Theme.of(context).colorScheme;
    final isHdp = market == MarketType.handicap;
    final team = onHome ? match.home : match.away;
    final odds = isHdp
        ? (onHome ? match.oddsHdpHome : match.oddsHdpAway)
        : (onHome ? match.oddsHome : match.oddsAway);
    final label = isHdp
        ? '$team ${_fmtLine(onHome ? match.homeHandicap : -match.homeHandicap)}'
        : team;
    final selected = g.isSelected(match, onHome, market: market);
    final placed =
        g.isBetPlaced(match, onHome, market: market); // da dat phieu, cho ket qua

    if (match.played) {
      if (isHdp) {
        // Keo chap: khong ket luan thang/thua tren the (co the an nua/hoan/
        // thua nua) — chi hien lai cua da chon, mau trung tinh.
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: scheme.surfaceContainerHighest,
          ),
          child: Column(
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
              Text('@${odds.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: scheme.outline)),
            ],
          ),
        );
      }
      final isWinner = match.homeGoals != match.awayGoals && onHome == match.homeWon;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isWinner
              ? Colors.green.withValues(alpha: .22)
              : scheme.surfaceContainerHighest,
        ),
        child: Text(
          isWinner ? '$team ✓ thắng' : '$team thua',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isWinner ? Colors.lightGreen : scheme.outline,
          ),
        ),
      );
    }

    return ScaleTap(
      onTap: () {
        final wasSelected = g.isSelected(match, onHome, market: market);
        g.toggleSelection(match, onHome, market: market);
        // Vua chon keo -> truot sidebar phieu cuoc ra cho nguoi choi thay
        // (man chi tiet tran khong co drawer nen phai kiem tra truoc)
        if (!wasSelected) {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.hasEndDrawer ?? false) {
            scaffold!.openEndDrawer();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: selected
              ? kBrandGradient
              : placed
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .07),
                        Colors.white.withValues(alpha: .03),
                      ],
                    ),
          color: selected
              ? null
              : placed
                  ? kGold.withValues(alpha: .14)
                  : null,
          border: Border.all(
            color: selected || placed
                ? kGold
                : Colors.white.withValues(alpha: .1),
            width: selected || placed ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: kGold.withValues(alpha: .45),
                      blurRadius: 14,
                      spreadRadius: 1),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (placed) ...[
                  const Icon(Icons.check_circle, size: 12, color: kGold),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected || placed
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
                placed && !selected
                    ? '@${odds.toStringAsFixed(2)} • ĐÃ ĐẶT'
                    : '@${odds.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: placed && !selected ? 13 : 16,
                  fontWeight: FontWeight.w800,
                  color: selected || placed ? kGold : scheme.primary,
                )),
          ],
        ),
      ),
    );
  }
}

/// Dinh dang line chap: co dau +/- ro rang, bo so 0 thua ("-0.5", "+0.75",
/// "0", "+1").
String _fmtLine(double v) {
  if (v == 0) return '0';
  final sign = v > 0 ? '+' : '-';
  var s = v.abs().toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return '$sign$s';
}
