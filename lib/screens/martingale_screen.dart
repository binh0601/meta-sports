import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../widgets/stat_card.dart';

/// Muc 8 tai lieu: vi sao gap thep (Martingale) that bai voi odds 1.90.
class MartingaleScreen extends StatefulWidget {
  const MartingaleScreen({super.key});

  @override
  State<MartingaleScreen> createState() => _MartingaleScreenState();
}

class _MartingaleScreenState extends State<MartingaleScreen> {
  final _rng = Random();
  final List<String> _log = [];
  double _bankroll = 10000; // 10 trieu (don vi k)
  int _cycles = 0;
  bool _busted = false;

  void _reset() => setState(() {
        _bankroll = 10000;
        _cycles = 0;
        _busted = false;
        _log.clear();
      });

  void _run(int cycles) {
    setState(() {
      for (var i = 0; i < cycles && !_busted; i++) {
        final r = BettingMath.martingaleCycle(_bankroll, 100, _rng);
        _cycles++;
        if (r.busted) {
          _busted = true;
          _log.insert(0,
              'Chu kỳ $_cycles: thua ${r.losses} lần liên tiếp, không đủ tiền '
              'gấp tiếp → CHÁY TÚI. Còn lại ${fmtK(r.bankroll)}.');
          _bankroll = r.bankroll;
        } else {
          final delta = r.bankroll - _bankroll;
          _bankroll = r.bankroll;
          _log.insert(0,
              'Chu kỳ $_cycles: thắng sau ${r.losses} lần thua, '
              'net ${fmtK(delta)} → số dư ${fmtK(_bankroll)}.');
          if (_log.length > 30) _log.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Martingale — gấp thếp')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoteBox(
            'Ý tưởng: thua thì gấp đôi tiền cược, thắng là hồi vốn. '
            'Với odds 1.90 nó thậm chí KHÔNG hồi được vốn: '
            'net = 100 − 10 × 2^k (nghìn đồng, k = số lần thua trước khi thắng).',
          ),
          const SectionTitle('Net sau chuỗi thua rồi thắng'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (var k = 1; k <= 6; k++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text('Thua $k lần rồi thắng')),
                          Text(
                            fmtK(BettingMath.martingaleNet(k)),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: BettingMath.martingaleNet(k) >= 0
                                  ? Colors.lightGreen
                                  : scheme.error,
                            ),
                          ),
                          if (BettingMath.martingaleNet(k) < 0)
                            const Text(' ❌'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const NoteBox(
            'Từ lần thua thứ 4 trở đi, DÙ CÓ THẮNG bạn vẫn âm — vì bạn chỉ '
            'được trả 90%, không phải 100%. Muốn thật sự hồi vốn phải nhân '
            '~2,22 lần mỗi vòng, và vốn cháy còn nhanh hơn.',
            icon: Icons.warning_amber,
          ),
          const SectionTitle('Mô phỏng: vốn 10 triệu, cược gốc 100k'),
          StatRow(cards: [
            StatCard(
              label: 'Số dư',
              value: fmtK(_bankroll),
              valueColor:
                  _bankroll >= 10000 ? Colors.lightGreen : scheme.error,
            ),
            StatCard(label: 'Chu kỳ đã chạy', value: '$_cycles'),
            StatCard(
              label: 'Trạng thái',
              value: _busted ? 'CHÁY TÚI' : 'Còn sống',
              valueColor: _busted ? scheme.error : Colors.lightGreen,
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busted ? null : () => _run(1),
                  child: const Text('Chạy 1 chu kỳ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _busted ? null : () => _run(50),
                  child: const Text('Chạy 50 chu kỳ'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm lại',
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in _log.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: line.contains('CHÁY')
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      )),
            ),
          const SizedBox(height: 8),
          const NoteBox(
            'P(thua 7 lần liên tiếp) = 1/128 ≈ 0,78%. Nghe nhỏ — nhưng chơi '
            '128 chu kỳ thì kỳ vọng cháy một lần, và một lần cháy xóa sạch '
            'hàng trăm lần lãi vài chục k. Martingale không đổi kỳ vọng, '
            'chỉ đổi hình dạng rủi ro: từ nhiều vết cắt nhỏ thành một nhát chém.',
            icon: Icons.local_fire_department,
          ),
          const SectionTitle('Kelly criterion nói gì?'),
          const NoteBox(
            'f* = (p×b − q)/b = (0.5×0.9 − 0.5)/0.9 = −0.055 < 0. '
            'Công thức đặt cược nổi tiếng nhất lịch sử, khi đưa vào kèo nhà '
            'cái, trả về đáp án: ĐỪNG ĐẶT CƯỢC.',
            icon: Icons.functions,
          ),
        ],
      ),
    );
  }
}
