import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/xac_suat_game.dart';
import 'xac_suat_style.dart';

/// Dai lich su ket qua (kieu bang cau) + panel bien nha cai thuc te.
class XsHistoryStrip extends StatelessWidget {
  final XsGame game;
  const XsHistoryStrip({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final recent = game.history.reversed.take(12).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('KẾT QUẢ GẦN ĐÂY',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const Spacer(),
        _edgeChip(),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 40,
        child: recent.isEmpty
            ? const Center(
                child: Text('Chưa có kỳ nào — chờ mở kết quả đầu tiên…',
                    style: TextStyle(color: Colors.white38, fontSize: 12)))
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _dot(recent[i].result),
              ),
      ),
    ]);
  }

  Widget _dot(int result) {
    final color = xsNumberColor(result);
    final special = xsNumberIsSpecial(result);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: special ? kXsSpecial : color, width: 2),
      ),
      child: Text('$result',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }

  Widget _edgeChip() {
    final edge = game.stats.actualEdge;
    final wagered = game.stats.totalWagered;
    final label = edge == null
        ? 'biên nhà cái: —'
        : 'nhà cái ăn ${fmtPct(edge)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.trending_down, size: 13, color: Color(0xFFEF4444)),
        const SizedBox(width: 4),
        Text(
            wagered > 0 ? '$label · đã cược ${fmtMoney(wagered)}' : label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}
