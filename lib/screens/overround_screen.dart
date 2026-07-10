import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../widgets/stat_card.dart';

/// Muc 3 tai lieu: keo odds -> xac suat ngam, overround, hold, ky vong.
class OverroundScreen extends StatefulWidget {
  const OverroundScreen({super.key});

  @override
  State<OverroundScreen> createState() => _OverroundScreenState();
}

class _OverroundScreenState extends State<OverroundScreen> {
  double _oddsA = 1.90;
  double _oddsB = 1.90;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final probA = BettingMath.impliedProb(_oddsA);
    final probB = BettingMath.impliedProb(_oddsB);
    final over = BettingMath.overround([_oddsA, _oddsB]);
    final hold = BettingMath.hold(over);
    // Ky vong khi cuoc cua A 100k, gia su xac suat that = xac suat ngam da
    // chuan hoa (ban du doan "chinh xac tuyet doi" nhu tai lieu).
    final trueProbA = probA / (probA + probB);
    final ev = BettingMath.evPerBet(stake: 100, odds: _oddsA, p: trueProbA);

    return Scaffold(
      appBar: AppBar(title: const Text('Biên nhà cái (Overround)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoteBox(
            'Odds 2.50 nghĩa là xác suất ngầm 1/2.50 = 40%. Nếu công bằng, '
            'tổng xác suất ngầm mọi cửa phải bằng đúng 100%. '
            'Nó không bao giờ bằng — kéo thử 2 thanh odds bên dưới.',
          ),
          const SectionTitle('Chỉnh odds hai cửa'),
          _oddsSlider('Cửa A', _oddsA, (v) => setState(() => _oddsA = v)),
          Text('Xác suất ngầm cửa A: ${fmtPct(probA)}'),
          const SizedBox(height: 12),
          _oddsSlider('Cửa B', _oddsB, (v) => setState(() => _oddsB = v)),
          Text('Xác suất ngầm cửa B: ${fmtPct(probB)}'),
          const SectionTitle('Nhà cái đang ăn bao nhiêu?'),
          StatRow(cards: [
            StatCard(
              label: 'Tổng xác suất ngầm',
              value: fmtPct(probA + probB),
              valueColor:
                  probA + probB > 1 ? scheme.error : Colors.lightGreen,
            ),
            StatCard(
              label: 'Overround',
              value: fmtPct(over),
              valueColor: over > 0 ? scheme.error : Colors.lightGreen,
            ),
          ]),
          const SizedBox(height: 8),
          StatRow(cards: [
            StatCard(label: 'Hold (biên/doanh thu)', value: fmtPct(hold)),
            StatCard(
              label: 'EV mỗi 100k cược',
              value: fmtK(ev),
              valueColor: ev < 0 ? scheme.error : Colors.lightGreen,
            ),
          ]),
          const SectionTitle('Ví dụ chuẩn: kèo 1.90 / 1.90'),
          _exampleTable(context),
          const SizedBox(height: 12),
          const NoteBox(
            'Hold 5% nghĩa là: trên mỗi 100k bạn cược, nhà cái giữ lại trung '
            'bình 5.000đ. Kể cả khi bạn dự đoán xác suất trận đấu chính xác '
            'tuyệt đối, bạn vẫn thua dài hạn — vì bạn được trả ít hơn mức '
            'công bằng.',
            icon: Icons.warning_amber,
          ),
        ],
      ),
    );
  }

  Widget _oddsSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 1.10,
            max: 3.50,
            divisions: 48,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _exampleTable(BuildContext context) {
    const rows = [
      ('Thua', 'mất 100k', 'mất 100k'),
      ('Thắng', 'ăn 100k', 'ăn 90k'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Table(
          children: [
            const TableRow(children: [
              Padding(padding: EdgeInsets.all(6), child: Text('')),
              Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Công bằng',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Nhà cái',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
            for (final r in rows)
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(6), child: Text(r.$1)),
                Padding(padding: const EdgeInsets.all(6), child: Text(r.$2)),
                Padding(padding: const EdgeInsets.all(6), child: Text(r.$3)),
              ]),
          ],
        ),
      ),
    );
  }
}
