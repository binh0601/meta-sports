import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../logic/xac_suat_game.dart';
import '../logic/xac_suat_math.dart';
import '../theme/brand_colors.dart';
import '../widgets/coin_burst.dart';
import '../widgets/xac_suat_bet_pad.dart';
import '../widgets/xac_suat_history_strip.dart';
import '../widgets/xac_suat_result_board.dart';

/// Man "KEO CHOP · 30 giay" — game doan tong ban thang, vi dung chung.
class XacSuatScreen extends StatefulWidget {
  const XacSuatScreen({super.key});

  @override
  State<XacSuatScreen> createState() => _XacSuatScreenState();
}

class _XacSuatScreenState extends State<XacSuatScreen> {
  static const _stakeOptions = [10000.0, 50000.0, 100000.0, 500000.0];
  double _stake = 100000;

  @override
  void initState() {
    super.initState();
    xsGame.start();
  }

  void _onBet(XsBetKind kind, {int? exactValue}) {
    final outcome = xsGame.placeBet(kind, _stake, exactValue: exactValue);
    if (outcome == XsBetOutcome.ok) return;
    final msg = switch (outcome) {
      XsBetOutcome.notBetting => 'Đã khoá kèo — chờ kỳ sau',
      XsBetOutcome.insufficient => 'Số dư không đủ để đặt',
      XsBetOutcome.oppositePair => 'Không đặt cả Tài lẫn Xỉu trong cùng kỳ',
      XsBetOutcome.tooManyNumbers => 'Tối đa 7 số "đúng tổng" mỗi kỳ',
      XsBetOutcome.ok => '',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(msg), duration: const Duration(milliseconds: 1400)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([xsGame, gameState]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _header(),
              const SizedBox(height: 14),
              XsResultBoard(game: xsGame),
              const SizedBox(height: 16),
              _stakeChips(),
              const SizedBox(height: 14),
              XsBetPad(game: xsGame, stake: _stake, onBet: _onBet),
              const SizedBox(height: 20),
              XsHistoryStrip(game: xsGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bolt, color: kGold, size: 22),
            const SizedBox(width: 4),
            Text('KÈO CHỚP', style: displayStyle(size: 20, color: Colors.white)),
          ]),
          const Text('xu ảo · học tập — trận chớp 30 giây',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
      CoinBurst(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.account_balance_wallet, size: 15, color: kGold),
            const SizedBox(width: 6),
            Text(fmtMoney(gameState.balance),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
        ),
      ),
    ]);
  }

  Widget _stakeChips() {
    return Row(children: [
      _modeToggle(),
      const SizedBox(width: 8),
      Expanded(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 6,
          runSpacing: 6,
          children: _stakeOptions.map((v) {
          final sel = _stake == v;
          return ChoiceChip(
            label: Text('${(v / 1000).round()}k'),
            selected: sel,
            onSelected: (_) => setState(() => _stake = v),
            labelStyle: TextStyle(
                color: sel ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12),
            selectedColor: kGold,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            visualDensity: VisualDensity.compact,
          );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _modeToggle() {
    return SegmentedButton<XsMode>(
      segments: const [
        ButtonSegment(value: XsMode.real, label: Text('30s')),
        ButtonSegment(value: XsMode.fast, label: Text('Nhanh')),
      ],
      selected: {xsGame.mode},
      onSelectionChanged: (s) => xsGame.setMode(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
    );
  }
}
