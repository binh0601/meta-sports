import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../widgets/line_chart.dart';
import '../widgets/stat_card.dart';

/// Lich su cuoc cua nguoi choi: thong ke, bieu do so du, danh sach phieu.
/// (Cac phan tich "bien nha cai / ky vong am" chi hien ben admin.)
class BetHistoryScreen extends StatelessWidget {
  const BetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final scheme = Theme.of(context).colorScheme;
        final wonCount = g.settled.where((b) => b.won).length;
        return Scaffold(
          appBar: AppBar(title: const Text('Lịch sử cược')),
          body: g.syncing
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    StatRow(cards: [
                      StatCard(
                          label: 'Số phiếu đã đấu', value: '${g.betCount}'),
                      StatCard(
                          label: 'Phiếu thắng',
                          value:
                              '$wonCount/${g.betCount == 0 ? "-" : g.betCount}'),
                    ]),
                    const SizedBox(height: 8),
                    StatRow(cards: [
                      StatCard(
                          label: 'Tổng tiền đã cược',
                          value: fmtMoney(g.totalStaked)),
                      StatCard(
                        label: 'Lãi/lỗ',
                        value: fmtK(g.netProfit),
                        valueColor: g.netProfit >= 0
                            ? Colors.lightGreen
                            : scheme.error,
                      ),
                    ]),
                    if (g.balanceHistory.length > 1) ...[
                      const SectionTitle('Số dư qua từng phiếu'),
                      LineChart(
                        series: [
                          ChartSeries(
                            [
                              for (var i = 0;
                                  i < g.balanceHistory.length;
                                  i++)
                                Offset(i.toDouble(), g.balanceHistory[i])
                            ],
                            g.netProfit >= 0
                                ? Colors.lightGreen
                                : Colors.redAccent,
                            'Số dư',
                          ),
                        ],
                        yFormat: (v) => fmtMoney(v),
                        xFormat: (v) => 'phiếu ${v.round()}',
                      ),
                    ],
                    const SectionTitle('Các phiếu đã đấu'),
                    if (g.settled.isEmpty)
                      Text('Chưa có phiếu nào — vào tab Trận đấu đặt thử.',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    for (final b in g.settled.reversed)
                      Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            b.won ? Icons.check_circle : Icons.cancel,
                            color:
                                b.won ? Colors.lightGreen : scheme.error,
                          ),
                          title: Text(
                            'Vòng ${b.round} • ${b.legs == 1 ? "Kèo đơn" : "Xiên ${b.legs}"} '
                            '@${b.totalOdds.toStringAsFixed(2)} • cược ${fmtMoney(b.stake)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            b.legResults
                                .map((l) =>
                                    '${l.teamName} @${l.odds.toStringAsFixed(2)} ${l.won ? "✓" : "✗"}')
                                .join('  •  '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            fmtK(b.net),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  b.won ? Colors.lightGreen : scheme.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
