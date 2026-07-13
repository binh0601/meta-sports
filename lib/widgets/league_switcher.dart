import 'package:flutter/material.dart';

import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
import 'motion_effects.dart';

/// 2 pill chon giai dau tren dau san keo — bam sang giai khac se sinh
/// lai vong dau moi; con phieu cho ket qua thi bao SnackBar va giu nguyen.
class LeagueSwitcher extends StatelessWidget {
  const LeagueSwitcher({super.key});

  void _onTap(BuildContext context, League l) {
    final ok = gameState.switchLeague(l);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đá xong vòng này mới đổi giải được.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final active = gameState.league;
        return Row(
          children: [
            Expanded(child: _pill(context, League.asianCup, active)),
            const SizedBox(width: 8),
            Expanded(child: _pill(context, League.worldCup, active)),
          ],
        );
      },
    );
  }

  Widget _pill(BuildContext context, League l, League active) {
    final scheme = Theme.of(context).colorScheme;
    final selected = l == active;
    return ScaleTap(
      onTap: () => _onTap(context, l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? kBrandGradient : null,
          color: selected ? null : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kGold : scheme.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          l.label,
          textAlign: TextAlign.center,
          style: displayStyle(
            size: 11,
            spacing: 1.5,
            color: selected ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
