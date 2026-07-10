import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../widgets/line_chart.dart';
import '../widgets/stat_card.dart';

/// Muc 6 tai lieu: hai luc keo tien - bien nha cai (5k x n) va may rui
/// (95k x can n). Diem giao 361 van + mo phong Monte Carlo 10 nguoi choi.
class LongRunScreen extends StatefulWidget {
  const LongRunScreen({super.key});

  @override
  State<LongRunScreen> createState() => _LongRunScreenState();
}

class _LongRunScreenState extends State<LongRunScreen> {
  static const _presets = [1, 10, 100, 361, 1000, 10000];
  int _n = 10;
  final _rng = Random();
  List<List<double>> _paths = [];

  @override
  void initState() {
    super.initState();
    _simulate();
  }

  void _simulate() {
    setState(() {
      _paths =
          List.generate(10, (_) => BettingMath.simulateBankroll(1000, _rng));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final drift = BettingMath.houseDrift(_n);
    final swing = BettingMath.luckSwing(_n);
    final winners = BettingMath.winnersShare(_n);
    final luckStronger = swing > drift;

    return Scaffold(
      appBar: AppBar(title: const Text('Mới chơi vs chơi lâu: n và √n')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoteBox(
            'Bạn đi trên con dốc nghiêng xuống: mỗi bước tụt 5cm (biên nhà '
            'cái). Nhưng gió ngang hất bạn 95cm mỗi bước, ngẫu nhiên (may '
            'rủi). Gió gây ồn ào — dốc quyết định điểm đến.',
          ),
          const SectionTitle('Chọn số ván đã chơi (n)'),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text('$p'),
                  selected: _n == p,
                  onSelected: (_) => setState(() => _n = p),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StatRow(cards: [
            StatCard(label: 'Biên nhà cái\n5k × n', value: fmtK(-drift)),
            StatCard(label: 'May rủi\n95k × √n', value: '±${fmtK(swing)}'),
          ]),
          const SizedBox(height: 8),
          StatRow(cards: [
            StatCard(
              label: 'Ai mạnh hơn?',
              value: luckStronger
                  ? 'May rủi (×${(swing / drift).toStringAsFixed(1)})'
                  : _n == BettingMath.crossoverGames
                      ? 'Hòa nhau'
                      : 'Nhà cái (×${(drift / swing).toStringAsFixed(1)})',
              valueColor: luckStronger ? Colors.lightGreen : scheme.error,
            ),
            StatCard(
              label: '% người còn lãi',
              value: winners < 0.0001
                  ? '≈ 0%'
                  : fmtPct(winners, winners < 0.01 ? 3 : 0),
              valueColor:
                  winners > 0.25 ? Colors.lightGreen : scheme.error,
            ),
          ]),
          const SectionTitle('Hai lực trên cùng biểu đồ — điểm giao 361 ván'),
          LineChart(
            series: [
              ChartSeries(
                [for (var n = 0; n <= 1000; n += 20)
                    Offset(n.toDouble(), BettingMath.houseDrift(n))],
                Colors.redAccent,
                'Biên nhà cái 5k × n',
              ),
              ChartSeries(
                [for (var n = 0; n <= 1000; n += 20)
                    Offset(n.toDouble(), BettingMath.luckSwing(n))],
                Colors.tealAccent,
                'May rủi 95k × √n',
              ),
            ],
            markX: BettingMath.crossoverGames.toDouble(),
            markLabel: 'n = 361',
            yFormat: (v) => '${(v / 1000).toStringAsFixed(1)}tr',
            xFormat: (v) => '${v.round()} ván',
          ),
          const SizedBox(height: 8),
          const NoteBox(
            'Trước ván 361, may rủi quyết định bạn thắng hay thua. '
            'Sau ván 361, biên nhà cái quyết định. Con số này không do nhà '
            'cái chọn — nó rơi ra từ chính tỷ lệ 90k/100k: 5n = 95√n → n = 361.',
          ),
          const SectionTitle('Mô phỏng 10 người chơi 1.000 ván'),
          LineChart(
            series: [
              for (final path in _paths)
                ChartSeries(
                  [for (var i = 0; i <= 1000; i += 10)
                      Offset(i.toDouble(), path[i])],
                  path.last >= 0
                      ? Colors.lightGreen
                      : Colors.redAccent.withValues(alpha: 0.6),
                  '',
                ),
              ChartSeries(
                [for (var n = 0; n <= 1000; n += 50)
                    Offset(n.toDouble(), -BettingMath.houseDrift(n))],
                Colors.amber,
                'Kỳ vọng −5k × n',
              ),
            ],
            yFormat: (v) => '${(v / 1000).toStringAsFixed(1)}tr',
            xFormat: (v) => '${v.round()}',
          ),
          const SizedBox(height: 8),
          Text(
            'Kết quả lần này: ${_paths.where((p) => p.last >= 0).length}/10 '
            'người còn lãi sau 1.000 ván (lý thuyết ~5%).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _simulate,
            icon: const Icon(Icons.refresh),
            label: const Text('Mô phỏng lại'),
          ),
          const SizedBox(height: 12),
          const NoteBox(
            'Sau ~10 ván, 43/100 người ra về có lãi — "mới chơi dễ thắng" '
            'là có thật. Nhà cái không cần bạn thua ván này. Họ chỉ cần '
            'bạn quay lại chơi tiếp: mỗi ván thêm, n tăng, và cả bảng trượt '
            'xuống một nấc, không thể đảo ngược.',
            icon: Icons.warning_amber,
          ),
        ],
      ),
    );
  }
}
