import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../logic/handicap_settlement.dart';
import '../theme/brand_colors.dart';
import 'motion_effects.dart';

/// Thanh tom tat duoi san keo: mo sidebar phieu cuoc + nut da vong.
/// Sau khi da vong: hien ket qua tung phieu + nut boc vong moi.
class BetSlipPanel extends StatelessWidget {
  const BetSlipPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: g.roundPlayed
              ? _results(context, g)
              : g.roundInPlay
                  ? _live(context, g)
                  : _summary(context, g),
        );
      },
    );
  }

  /// Truoc khi da: nut mo sidebar phieu + nut da vong.
  Widget _summary(BuildContext context, GameState g) {
    final scheme = Theme.of(context).colorScheme;
    final hasContent = g.slip.isNotEmpty || g.pending.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasContent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Bấm vào odds để chọn kèo — phiếu cược trượt ra từ cạnh phải.',
              style:
                  TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: Text(hasContent
                    ? 'Phiếu cược: ${g.slip.length} chọn • ${g.pending.length} chờ'
                    : 'Mở phiếu cược'),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.tonalIcon(
                icon: const SpinningBallIcon(size: 16),
                label: Text('Đá vòng ${g.roundNumber}'),
                onPressed: () => g.kickoffRound(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dang da: hien phut chay + goi y cuoc keo chap truc tiep (1x2 da khoa).
  Widget _live(BuildContext context, GameState g) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          const PulseDot(Colors.redAccent),
          const SizedBox(width: 8),
          Text("Đang đá — phút ${g.liveMinute}'",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${g.pending.length} phiếu chờ',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.bolt, size: 14, color: kGold),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Kèo chấp đang chạy — bấm odds kèo chấp trên trận để cược trực tiếp.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
        ]),
      ],
    );
  }

  /// Sau khi da: ket qua cac phieu + nut vong moi.
  Widget _results(BuildContext context, GameState g) {
    final scheme = Theme.of(context).colorScheme;
    final double roundNet =
        g.lastResults.fold(0.0, (double s, b) => s + b.net);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (g.lastResults.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Vòng này bạn không đặt phiếu nào.',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          )
        else ...[
          for (final b in g.lastResults)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: b.won
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.lightGreen),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.lightGreen.withValues(alpha: .35),
                              blurRadius: 12),
                        ],
                      ),
                      child: _betRow(b, scheme),
                    )
                  : ShakeOnce(child: _betRow(b, scheme)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Vòng này: ${fmtK(roundNet)}   •   Số dư: ${fmtMoney(g.balance)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => g.newRound(),
            icon: const Icon(Icons.arrow_forward),
            label: Text('Vòng ${g.roundNumber + 1} — bốc kèo mới'),
          ),
        ),
      ],
    );
  }

  /// Dong noi dung 1 phieu ket qua (dung chung cho ca thang/thua).
  Widget _betRow(BetSlip b, ColorScheme scheme) {
    // Ve don (chap hoac 1x2 1 chan): status tung chan chinh xac (chap co the
    // an nua/hoan/thua nua). Ve xien nhieu chan: mot chan thang khong dong
    // nghia ca phieu thang, nen lay ket qua toan phieu (b.won) de nhan khop
    // voi so tien lai/lo va hieu ung glow/shake.
    final status = b.legResults.length == 1
        ? b.legResults.first.status
        : (b.won ? SettleStatus.win : SettleStatus.lose);
    final (label, color) = _statusLabel(status);
    return Row(
      children: [
        Icon(b.won ? Icons.check_circle : Icons.cancel,
            size: 15, color: b.won ? Colors.lightGreen : scheme.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${b.legs == 1 ? "Đơn" : "Xiên ${b.legs}"} '
            '@${b.totalOdds.toStringAsFixed(2)} — cược ${fmtMoney(b.stake)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            Text(fmtK(b.net),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: b.won ? Colors.lightGreen : scheme.error,
                )),
          ],
        ),
      ],
    );
  }

  /// Nhan tieng Viet + mau cho tung trang thai cham keo chap (va thang/thua
  /// nhi phan cua 1x2, quy ve win/lose).
  (String, Color) _statusLabel(SettleStatus s) => switch (s) {
        SettleStatus.win => ('Ăn đủ', Colors.lightGreen),
        SettleStatus.halfWin => ('Ăn nửa', Colors.green),
        SettleStatus.push => ('Hoàn tiền', Colors.grey),
        SettleStatus.halfLose => ('Thua nửa', Colors.orange),
        SettleStatus.lose => ('Mất', Colors.red),
      };
}
