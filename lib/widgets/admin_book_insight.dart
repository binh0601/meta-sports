import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/football_market.dart';

/// The "so nha cai" cho 1 tran: lo xac suat that (nguoi choi khong thay)
/// va bien loi nhuan cua keo — goc nhin chi admin/nha cai co.
class AdminBookInsight extends StatelessWidget {
  final FootballMatch match;
  const AdminBookInsight({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = BettingMath.overround([match.oddsHome, match.oddsAway]);
    final hold = BettingMath.hold(over);
    final pHome = match.trueProbHome;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(match.flagHome,
                      width: 18, height: 12, fit: BoxFit.cover),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${match.home}  vs  ${match.away}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(match.flagAway,
                      width: 18, height: 12, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Text(
                  '@${match.oddsHome.toStringAsFixed(2)} / @${match.oddsAway.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Thanh xac suat that: phan xanh = doi nha, phan cham = doi khach
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pHome,
                minHeight: 8,
                backgroundColor: Colors.indigo.withValues(alpha: .45),
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('P(thật) ${match.home}: ${fmtPct(pHome, 0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.teal)),
                Text('P(thật) ${match.away}: ${fmtPct(1 - pHome, 0)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.indigoAccent)),
                Text('Hold ${fmtPct(hold, 1)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.error)),
              ],
            ),
            if (match.played)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Kết quả: ${match.homeWon ? match.home : match.away} thắng ${match.score}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.lightGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
