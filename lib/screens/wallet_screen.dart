import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../logic/wallet_rules.dart';
import '../theme/brand_colors.dart';

/// Man vi tien: so du, tien do rollover, nap tu do, rut toan bo (gia lap).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountCtrl = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient)),
      ),
      body: ListenableBuilder(
        listenable: gameState,
        builder: (context, _) {
          final g = gameState;
          final w = g.wallet;
          final blockReason = w.withdrawBlockReason(
              balance: g.balance, hasPending: g.pending.isNotEmpty);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(g.balance),
              const SizedBox(height: 16),
              _rolloverCard(w),
              const SizedBox(height: 16),
              _depositCard(),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.savings),
                label: Text(blockReason == null
                    ? 'Rút toàn bộ ${fmtMoney(g.balance)}'
                    : 'Rút tiền'),
                onPressed: blockReason == null ? _withdraw : null,
              ),
              if (blockReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(blockReason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceCard(double balance) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('SỐ DƯ HIỆN TẠI',
                style: TextStyle(
                    fontSize: 11, letterSpacing: 2, color: Colors.white70)),
            const SizedBox(height: 6),
            Text(fmtMoney(balance),
                style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: kGold)),
          ],
        ),
      );

  Widget _rolloverCard(WalletRules w) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Điều kiện rút tiền (rollover ×5)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Tiền được cấp/nạp phải cược đủ 5 lần trước khi rút — '
                'giống điều khoản khuyến mãi của nhà cái thật.',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: w.progress, minHeight: 10, color: kGold),
              ),
              const SizedBox(height: 6),
              Text(
                'Đã cược ${fmtMoney(w.totalWagered)} / '
                'cần ${fmtMoney(w.requirement)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _depositCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nạp tiền (giả lập)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tiền (nghìn đồng)',
                        hintText: 'VD: 500 = 500k',
                        errorText: _inputError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                      onPressed: _deposit, child: const Text('Nạp')),
                ],
              ),
            ],
          ),
        ),
      );

  void _deposit() {
    final v = double.tryParse(_amountCtrl.text.trim());
    if (v == null || v <= 0) {
      setState(() => _inputError = 'Nhập số tiền hợp lệ (> 0).');
      return;
    }
    setState(() => _inputError = null);
    gameState.deposit(v);
    _amountCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã nạp ${fmtMoney(v)} — cần cược thêm '
            '${fmtMoney(v * 5)} để đủ điều kiện rút.')));
  }

  void _withdraw() {
    final amount = gameState.withdrawAll();
    if (amount <= 0) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rút tiền thành công 🎉'),
        content: Text('Đã rút ${fmtMoney(amount)} (giả lập — không có '
            'tiền thật). Ví về 0, nạp để chơi tiếp.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
