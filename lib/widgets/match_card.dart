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
    final scheme = Theme.of(context).colorScheme;
    return EntranceSlide(
      index: index,
      child: Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
      ),
      child: ScaleTap(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _team(match.home, match.flagHome, false)),
                  _centerBadge(context),
                  Expanded(child: _team(match.away, match.flagAway, true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: OddsSelectButton(match: match, onHome: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OddsSelectButton(match: match, onHome: false)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Xem nhận định & phong độ ›',
                style: TextStyle(fontSize: 10, color: scheme.outline),
              ),
            ],
          ),
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
        child: Image.asset(flag, width: 30, height: 20, fit: BoxFit.cover),
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
              color: match.played
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
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
          Text(
            match.played ? 'KẾT THÚC' : 'HÔM NAY',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              color: match.played ? Colors.lightGreen : scheme.outline,
            ),
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
  const OddsSelectButton(
      {super.key, required this.match, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final g = gameState;
    final scheme = Theme.of(context).colorScheme;
    final team = onHome ? match.home : match.away;
    final odds = onHome ? match.oddsHome : match.oddsAway;
    final selected = g.isSelected(match, onHome);
    final placed = g.isBetPlaced(match, onHome); // da dat phieu, cho ket qua

    if (match.played) {
      final isWinner = onHome == match.homeWon;
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
        final wasSelected = g.isSelected(match, onHome);
        g.toggleSelection(match, onHome);
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
          gradient: selected ? kBrandGradient : null,
          color: selected
              ? null
              : placed
                  ? kGold.withValues(alpha: .14)
                  : scheme.surfaceContainerHighest,
          border: Border.all(
            color: selected || placed ? kGold : scheme.outlineVariant,
            width: selected || placed ? 1.4 : 1,
          ),
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
                  child: Text(team,
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
