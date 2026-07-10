import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../widgets/stat_card.dart';

/// Muc 4-5 tai lieu: so can va so lech, ban choi tong bang khong.
/// 10 nguoi, moi nguoi 100k; keo slider so nguoi dat cua A.
class BookBalanceScreen extends StatefulWidget {
  const BookBalanceScreen({super.key});

  @override
  State<BookBalanceScreen> createState() => _BookBalanceScreenState();
}

class _BookBalanceScreenState extends State<BookBalanceScreen> {
  int _a = 5; // so nguoi dat cua A (0..10)

  String get _status {
    final d = (_a - 5).abs();
    if (d == 0) return '✅ CÂN — nhà cái lãi chắc chắn';
    if (d <= 1) return 'Lệch nhẹ';
    if (d <= 2) return 'Lệch';
    if (d <= 4) return 'Lệch nặng';
    return 'Lệch cực đại';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ifA = BettingMath.bookProfitIfAWins(_a);
    final ifB = BettingMath.bookProfitIfBWins(_a);
    final safe = ifA >= 0 && ifB >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sổ cân & sổ lệch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoteBox(
            '"Sổ" = sổ ghi tiền đặt cược. Nhà cái không nhìn trận đấu — '
            'họ nhìn cuốn sổ này. 10 người chơi, mỗi người cược 100k. '
            'Kéo slider để chia tiền vào 2 cửa.',
          ),
          const SectionTitle('Chia tiền vào 2 cửa'),
          Row(
            children: [
              Text('A: $_a người',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _a.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_a đặt A / ${10 - _a} đặt B',
                  onChanged: (v) => setState(() => _a = v.round()),
                ),
              ),
              Text('B: ${10 - _a} người',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          // Thanh truc quan ty le tien 2 cua
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: _a == 0 ? 1 : _a * 10,
                  child: Container(
                    height: 22,
                    color: _a == 0 ? Colors.transparent : Colors.teal,
                    alignment: Alignment.center,
                    child: _a > 0
                        ? Text('${_a * 100}k',
                            style: const TextStyle(fontSize: 11))
                        : null,
                  ),
                ),
                Expanded(
                  flex: _a == 10 ? 1 : (10 - _a) * 10,
                  child: Container(
                    height: 22,
                    color: _a == 10 ? Colors.transparent : Colors.indigo,
                    alignment: Alignment.center,
                    child: _a < 10
                        ? Text('${(10 - _a) * 100}k',
                            style: const TextStyle(fontSize: 11))
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Lãi / lỗ của nhà cái theo kết quả'),
          StatRow(cards: [
            StatCard(
              label: 'Nếu A ra',
              value: fmtK(ifA),
              valueColor: ifA >= 0 ? Colors.lightGreen : scheme.error,
            ),
            StatCard(
              label: 'Nếu B ra',
              value: fmtK(ifB),
              valueColor: ifB >= 0 ? Colors.lightGreen : scheme.error,
            ),
            StatCard(
              label: 'Trạng thái sổ',
              value: _status,
              valueColor: safe ? Colors.lightGreen : scheme.error,
            ),
          ]),
          const SizedBox(height: 12),
          NoteBox(
            safe
                ? 'Sổ cân: lãi cố định 50k bất kể kết quả. Rủi ro = 0. '
                    'Đây là nghề thật của nhà cái — thu phí trung gian.'
                : 'Sổ lệch: nhà cái đang ĐÁNH BẠC. Một cửa ra là họ lỗ thật, '
                    'móc vốn ra trả. Vì thế họ chỉnh odds, đặt trần cược, ra '
                    'kèo chấp, hoặc đẩy kèo sang nhà cái khác để kéo sổ về cân.',
            icon: safe ? Icons.verified : Icons.local_fire_department,
          ),
          const SectionTitle('Bàn chơi tổng bằng không (sổ cân, A ra)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: const [
                  _ZeroSumRow('5 người thắng', '5 × (+90k)', '+450k'),
                  _ZeroSumRow('5 người thua', '5 × (−100k)', '−500k'),
                  Divider(),
                  _ZeroSumRow('Tổng người chơi', '', '−50k'),
                  _ZeroSumRow('Nhà cái', '', '+50k'),
                  Divider(),
                  _ZeroSumRow('Cộng lại', '', '0'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const NoteBox(
            'Bạn không cạnh tranh với nhà cái. Bạn cạnh tranh với 9 người kia '
            '— nhưng phải trả tiền vé vào cửa cho nhà cái. 10 người gộp lại '
            'thì chắc chắn lỗ, không có ngoại lệ.',
            icon: Icons.warning_amber,
          ),
        ],
      ),
    );
  }
}

class _ZeroSumRow extends StatelessWidget {
  final String label;
  final String formula;
  final String total;
  const _ZeroSumRow(this.label, this.formula, this.total);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
              flex: 3,
              child: Text(formula,
                  style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            flex: 2,
            child: Text(total,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
