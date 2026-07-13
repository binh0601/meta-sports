import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../logic/wallet_rules.dart';
import '../theme/brand_colors.dart';
import 'admin_dashboard_screen.dart';
import 'qr_payment_screen.dart';
import 'bank_info_screen.dart';
import '../services/player_repository.dart';

/// Man vi tien: so du, tien do rollover, nap tu do, rut toan bo (gia lap).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountCtrl = TextEditingController();
  final _withdrawCtrl = TextEditingController();
  String? _inputError;
  String? _withdrawError;
  bool _isWithdrawing = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _withdrawCtrl.dispose();
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
              _withdrawCard(g, w, blockReason),
              const SizedBox(height: 32),
              if (FirebaseAuth.instance.currentUser?.email == 'admin@gmail.com')
                TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                  label: const Text('Dành cho Quản trị viên (Duyệt nạp/rút)', style: TextStyle(color: Colors.amber)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
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
              const Text('Nạp tiền chuyển khoản',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tiền nạp',
                        hintText: 'VD: 500k hoặc 500.000',
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

  void _deposit() async {
    final text = _amountCtrl.text.trim();
    final v = double.tryParse(text);
    if (v == null || v <= 0) {
      setState(() => _inputError = 'Nhập số tiền hợp lệ (> 0).');
      return;
    }

    // Nếu nhập dưới 1000, coi như nhập đơn vị nghìn (VD: 500 -> 500.000đ)
    final int amountVnd = (v < 1000) ? (v * 1000).round() : v.round();
    
    if (amountVnd < 10000) {
      setState(() => _inputError = 'Số tiền tối thiểu là 10.000đ.');
      return;
    }
    
    setState(() => _inputError = null);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bạn cần đăng nhập bằng tài khoản thành viên để nạp tiền.'),
      ));
      return;
    }

    _amountCtrl.clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrPaymentScreen(
          amountVnd: amountVnd.toDouble(),
        ),
      ),
    );
  }

  Widget _withdrawCard(GameState g, WalletRules w, String? blockReason) {
    final hasBankInfo = g.bankName != null && g.bankAccountNo != null && g.bankAccountName != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rút tiền về Ngân hàng', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            
            if (blockReason != null)
              Text(blockReason, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13))
            else if (!hasBankInfo)
              Column(
                children: [
                  const Text('Bạn cần cập nhật thông tin tài khoản ngân hàng trước khi rút tiền.', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  FilledButton(onPressed: _openBankInfo, child: const Text('Cập nhật Ngân hàng')),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _withdrawCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tiền rút',
                        hintText: 'Tối đa: ${fmtMoney(g.balance)}',
                        errorText: _withdrawError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _isWithdrawing ? null : _withdraw,
                    child: _isWithdrawing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('Rút'),
                  ),
                ],
              ),
              
            if (hasBankInfo && blockReason == null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nhận tiền qua: ${g.bankName}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  TextButton(onPressed: _openBankInfo, child: const Text('Sửa', style: TextStyle(fontSize: 12))),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  void _openBankInfo() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BankInfoScreen()));
  }

  void _withdraw() async {
    final text = _withdrawCtrl.text.trim();
    final v = double.tryParse(text);
    if (v == null || v <= 0) {
      setState(() => _withdrawError = 'Nhập số hợp lệ');
      return;
    }
    
    final int amountVnd = (v < 1000) ? (v * 1000).round() : v.round();
    
    if (amountVnd < 50000) {
      setState(() => _withdrawError = 'Tối thiểu 50.000đ');
      return;
    }
    
    final g = gameState;
    if (amountVnd > g.balance) {
      setState(() => _withdrawError = 'Số dư không đủ');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _withdrawError = null;
      _isWithdrawing = true;
    });

    final success = await PlayerRepository.instance.createWithdrawRequest(
      uid: user.uid,
      username: user.displayName ?? user.email ?? 'Member',
      amountVnd: amountVnd,
      bankName: g.bankName!,
      bankAccountNo: g.bankAccountNo!,
      bankAccountName: g.bankAccountName!,
    );
    
    if (mounted) {
      setState(() => _isWithdrawing = false);
      if (success) {
        _withdrawCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã gửi yêu cầu rút tiền thành công! Admin sẽ duyệt sớm nhất.'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lỗi khi gửi yêu cầu rút tiền. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

