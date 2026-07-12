import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';

/// Tab "Toi": ho so nguoi choi, so du, thanh tich va dang xuat.
class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header: anh bong da that + phu gradient, avatar + so du
              Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/images/ball_closeup.jpg',
                        fit: BoxFit.cover),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xCC2563EB), Color(0xE61E1B4B)],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: .15),
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      authState.username.isEmpty
                          ? 'user'
                          : authState.username,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const Text('Người chơi demo',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kGold),
                      ),
                      child: Text(
                        'Số dư: ${fmtMoney(g.balance)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kGold),
                      ),
                    ),
                  ],
                ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Thành tích'),
                    StatRow(cards: [
                      StatCard(
                          label: 'Số phiếu đã đấu',
                          value: '${g.betCount}'),
                      StatCard(
                          label: 'Tổng đã cược',
                          value: fmtMoney(g.totalStaked)),
                      StatCard(
                        label: 'Lãi/lỗ',
                        value: fmtK(g.netProfit),
                        valueColor: g.netProfit >= 0
                            ? Colors.lightGreen
                            : scheme.error,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (!authState.isDemo) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Nạp / Rút tiền'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WalletScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Chơi lại từ đầu'),
                        onPressed: () => _confirmReset(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.errorContainer,
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Đăng xuất'),
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await authState.logout();
                          nav.pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chơi lại từ đầu?'),
        content: Text('Ví về ${fmtMoney(gameState.isDemoWallet
            ? GameState.demoBalance
            : GameState.startBalance)}, xóa toàn bộ lịch sử cược.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              gameState.reset();
              Navigator.pop(ctx);
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }
}
