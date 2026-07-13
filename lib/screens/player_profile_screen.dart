import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../logic/wallet_rules.dart';
import '../theme/brand_colors.dart';
import '../widgets/motion_effects.dart';
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
        final gain = g.netProfit >= 0;
        final gainColor = gain ? Colors.lightGreen : scheme.error;
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header: anh bong da that + phu gradient, avatar + so du
              Stack(children: [
                Positioned.fill(
                    child: Image.asset('assets/images/ball_closeup.jpg',
                        fit: BoxFit.cover)),
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
                  child: _ProfileHeader(
                      balance: g.balance, isDemo: authState.isDemo),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntranceSlide(
                      index: 0,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Thành tích'),
                            StatRow(cards: [
                              StatCard(
                                  label: 'Số phiếu đã đấu',
                                  value: '${g.betCount}',
                                  icon: Icons.receipt_long,
                                  accentColor: Colors.blueAccent),
                              StatCard(
                                  label: 'Tổng đã cược',
                                  value: fmtMoney(g.totalStaked),
                                  icon: Icons.payments,
                                  accentColor: kGold),
                              StatCard(
                                  label: 'Lãi/lỗ',
                                  value: fmtK(g.netProfit),
                                  icon: gain
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  accentColor: gainColor,
                                  valueColor: gainColor),
                            ]),
                          ]),
                    ),
                    if (!authState.isDemo) ...[
                      const SizedBox(height: 16),
                      EntranceSlide(
                          index: 1, child: _RolloverCard(wallet: g.wallet)),
                    ],
                    const SizedBox(height: 16),
                    if (!authState.isDemo) ...[
                      EntranceSlide(
                        index: 2,
                        child: Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              gradient: kBrandGradient,
                              borderRadius: BorderRadius.circular(12)),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.account_balance_wallet,
                                size: 20),
                            label: const Text('Nạp / Rút tiền'),
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const WalletScreen())),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    EntranceSlide(
                      index: 3,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.restart_alt, size: 20),
                          label: const Text('Chơi lại từ đầu'),
                          onPressed: () => _confirmReset(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    EntranceSlide(
                      index: 4,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: scheme.errorContainer,
                              foregroundColor: scheme.onErrorContainer),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Đăng xuất'),
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            await authState.logout();
                            nav.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (_) => false);
                          },
                        ),
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

/// Avatar ring gradient + ten display font + pill vai tro + pill so du.
class _ProfileHeader extends StatelessWidget {
  final double balance;
  final bool isDemo;
  const _ProfileHeader({required this.balance, required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [kGold, Color(0xFF2563EB)]),
        ),
        child: const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFF1E1B4B),
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
      ),
      const SizedBox(height: 10),
      Text(authState.username.isEmpty ? 'user' : authState.username,
          style: displayStyle(size: 22)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .3)),
        ),
        child: Text(isDemo ? 'NGƯỜI CHƠI DEMO' : 'THÀNH VIÊN',
            style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: .5)),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGold),
        ),
        child: Text('Số dư: ${fmtMoney(balance)}',
            style: displayStyle(size: 16, color: kGold)),
      ),
    ]);
  }
}

/// Card mini tien do rollover: da cuoc bao nhieu / can bao nhieu de rut.
class _RolloverCard extends StatelessWidget {
  final WalletRules wallet;
  const _RolloverCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Điều kiện rút',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: wallet.progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest),
          ),
          const SizedBox(height: 6),
          Text(
              'Đã cược ${fmtMoney(wallet.totalWagered)}'
              ' / cần ${fmtMoney(wallet.requirement)}',
              style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
