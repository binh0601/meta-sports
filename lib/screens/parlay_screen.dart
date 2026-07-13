import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../widgets/stat_card.dart';

/// Muc 9 tai lieu: cuoc xien nhan bien nha cai theo so keo ghep.
class ParlayScreen extends StatefulWidget {
  const ParlayScreen({super.key});

  @override
  State<ParlayScreen> createState() => _ParlayScreenState();
}

class _ParlayScreenState extends State<ParlayScreen> {
  int _k = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final margin = BettingMath.parlayMargin(_k);
    // Cuoc 100k, k keo odds 1.90: tien nhan neu trung het & xac suat trung.
    final payout = 100000 * pow(1.9, _k).toDouble();
    final winProb = pow(0.5, _k).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Cược xiên — cỗ máy nhân biên')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NoteBox(
            'Cược xiên (parlay): ghép nhiều kèo, phải đúng TẤT CẢ mới thắng. '
            'Mỗi kèo bạn chỉ giữ lại 95% giá trị công bằng — ghép k kèo, '
            'giá trị còn lại là 0.95^k.',
          ),
          const SectionTitle('Số kèo ghép'),
          Slider(
            value: _k.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_k kèo',
            onChanged: (v) => setState(() => _k = v.round()),
          ),
          StatRow(cards: [
            StatCard(
              label: 'Biên nhà cái',
              value: fmtPct(margin, 1),
              valueColor: margin > 0.1 ? scheme.error : Colors.orange,
            ),
            StatCard(
              label: 'Giá trị còn lại',
              value: fmtPct(1 - margin, 1),
            ),
          ]),
          const SizedBox(height: 8),
          StatRow(cards: [
            StatCard(
              label: 'Cược 100k, trúng hết nhận',
              value: fmtK(payout),
              valueColor: Colors.lightGreen,
            ),
            StatCard(
              label: 'Xác suất trúng hết',
              value: fmtPct(winProb, winProb < 0.01 ? 2 : 1),
              valueColor: scheme.error,
            ),
          ]),
          const SizedBox(height: 12),
          // Thanh truc quan: phan nha cai an theo so keo
          for (var k = 1; k <= 10; k++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 56, child: Text('$k kèo')),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: BettingMath.parlayMargin(k),
                        minHeight: 14,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: k == _k ? scheme.error : scheme.errorContainer,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      fmtPct(BettingMath.parlayMargin(k), 1),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight:
                            k == _k ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const NoteBox(
            'Payout nhìn cực hấp dẫn: cược 100k ăn vài triệu. Não người đánh '
            'giá "số tiền thắng" chứ không đánh giá "xác suất × số tiền '
            'thắng". Nhà cái biết điều này — vì thế cược xiên được quảng bá '
            'mạnh nhất, và nút "thêm kèo" luôn ở chỗ dễ bấm nhất.',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 8),
          const NoteBox(
            'Cược xiên là sản phẩm có biên lợi nhuận cao nhất của nhà cái, '
            'và được người chơi yêu thích nhất. Đó không phải trùng hợp.',
            icon: Icons.warning_amber,
          ),
        ],
      ),
    );
  }
}
