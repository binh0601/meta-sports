import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
import 'motion_effects.dart';

/// Sidebar phieu cuoc (endDrawer) truot tu canh phai nhu app ca cuoc that:
/// - Keo dang chon + o TU DIEN tien cuoc (100k chi la goi y ban dau)
/// - Danh sach phieu DANG CHO ket qua de nguoi choi thay ro minh da dat gi
class BetSlipDrawer extends StatefulWidget {
  const BetSlipDrawer({super.key});

  @override
  State<BetSlipDrawer> createState() => _BetSlipDrawerState();
}

class _BetSlipDrawerState extends State<BetSlipDrawer> {
  static const List<double> _suggestions = [50000, 100000, 200000, 500000, 1000000];
  late final TextEditingController _stakeCtrl =
      TextEditingController(text: gameState.stake.round().toString());

  @override
  void dispose() {
    _stakeCtrl.dispose();
    super.dispose();
  }

  void _applyStake(String v) => gameState.setStake(double.tryParse(v) ?? 0);

  void _fillStake(double v) {
    _stakeCtrl.text = v.round().toString();
    _applyStake(_stakeCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 330,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: gameState,
          builder: (context, _) {
            final g = gameState;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration:
                      const BoxDecoration(gradient: kBrandGradient),
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: kGold),
                      const SizedBox(width: 8),
                      const Text('PHIẾU CƯỢC',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (!g.roundPlayed) ...[
                        _label(context, 'ĐANG CHỌN (${g.slip.length})'),
                        if (g.slip.isEmpty)
                          Text(
                            'Chưa chọn kèo nào. Bấm vào odds của đội bạn '
                            'muốn cược ngoài sàn.',
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant),
                          )
                        else ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final s in g.slip)
                                InputChip(
                                  label: Text(
                                      '${s.teamName} @${s.odds.toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  onDeleted: () =>
                                      g.toggleSelection(s.match, s.onHome),
                                ),
                            ],
                          ),
                          if (g.slip.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'KÈO XIÊN ${g.slip.length} trận — odds nhân '
                                'lên ${g.slipOdds.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFFFBBF24)),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _stakeCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: _applyStake,
                            decoration: const InputDecoration(
                              labelText: 'Tiền cược (nghìn đồng)',
                              helperText:
                                  'Tự điền số tiền — bên dưới là gợi ý nhanh',
                              prefixIcon: Icon(Icons.payments_outlined),
                              suffixText: 'k',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final v in _suggestions)
                                ActionChip(
                                  label: Text('${v.round()}k',
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  onPressed: () => _fillStake(v),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: g.canPlaceBet
                                  ? [
                                      BoxShadow(
                                          color: kGold.withValues(alpha: .4),
                                          blurRadius: 12),
                                    ]
                                  : null,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: g.canPlaceBet
                                    ? () {
                                        final msg =
                                            'Đã đặt ${fmtMoney(g.stake)} — trúng '
                                            'nhận ${fmtMoney(g.stake * g.slipOdds)}';
                                        g.placeBet();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(msg),
                                                duration: const Duration(
                                                    seconds: 2)));
                                      }
                                    : null,
                                child: Text(g.stake > g.balance
                                    ? 'Không đủ số dư'
                                    : 'Đặt ${fmtMoney(g.stake)} → trúng nhận '
                                        '${fmtMoney(g.stake * g.slipOdds)}'),
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 28),
                      ],
                      _label(context,
                          'ĐANG CHỜ KẾT QUẢ (${g.pending.length})'),
                      if (g.pending.isEmpty)
                        Text('Chưa có phiếu nào chờ.',
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                      for (final b in g.pending)
                        Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.hourglass_top,
                                color: kGold, size: 20),
                            title: Text(
                              '${b.legs == 1 ? "Kèo đơn" : "Xiên ${b.legs}"} '
                              '@${b.totalOdds.toStringAsFixed(2)} • cược ${fmtMoney(b.stake)}',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            subtitle: Text(
                              b.selections
                                  .map((s) =>
                                      '${s.teamName} @${s.odds.toStringAsFixed(2)}')
                                  .join('  •  '),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '+${fmtMoney(b.stake * b.totalOdds)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightGreen),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const SpinningBallIcon(),
                      label: Text(g.roundPlayed
                          ? 'Vòng đã đá — về sàn bốc vòng mới'
                          : 'Đá vòng ${g.roundNumber} ngay'),
                      onPressed: g.roundPlayed
                          ? () => Navigator.pop(context)
                          : () {
                              g.playRound();
                              Navigator.pop(context);
                            },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            )),
      );
}
