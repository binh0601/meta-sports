import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../services/notification_service.dart';
import '../widgets/admin_book_insight.dart';
import '../widgets/stat_card.dart';
import 'book_balance_screen.dart';
import 'login_screen.dart';
import 'long_run_screen.dart';
import 'martingale_screen.dart';
import 'overround_screen.dart';
import 'parlay_screen.dart';
import 'sportsbook_screen.dart';
import 'summary_screen.dart';

/// Dashboard "nha cai": thong ke tien, so keo voi xac suat that,
/// luat van hanh va toan bo logic/cong thuc — chi role admin thay.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final List<(String, IconData, Widget Function())> _topics = [
    ('Biên nhà cái (Overround)', Icons.percent, () => const OverroundScreen()),
    ('Sổ cân & sổ lệch', Icons.menu_book, () => const BookBalanceScreen()),
    ('n và √n — dài hạn', Icons.trending_down, () => const LongRunScreen()),
    ('Martingale — gấp thếp', Icons.casino, () => const MartingaleScreen()),
    ('Cược xiên — nhân biên', Icons.link, () => const ParlayScreen()),
    ('Bảng tổng kết', Icons.fact_check, () => const SummaryScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final scheme = Theme.of(context).colorScheme;
        final houseProfit = -g.netProfit;
        final realizedHold =
            g.totalStaked > 0 ? houseProfit / g.totalStaked : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bảng điều khiển Nhà cái'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await authState.logout();
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle('Thống kê dòng tiền (người chơi "user")'),
              StatRow(cards: [
                StatCard(
                    label: 'Tổng tiền đã cược',
                    value: fmtMoney(g.totalStaked)),
                StatCard(
                  label: 'Nhà cái lãi',
                  value: fmtK(houseProfit),
                  valueColor:
                      houseProfit >= 0 ? Colors.lightGreen : scheme.error,
                ),
              ]),
              const SizedBox(height: 8),
              StatRow(cards: [
                StatCard(label: 'Số phiếu đã đấu', value: '${g.betCount}'),
                StatCard(
                    label: 'Phiếu đang chờ',
                    value:
                        '${g.pending.length} (${fmtMoney(g.pendingStake)})'),
                StatCard(
                  label: 'Hold thực tế / lý thuyết',
                  value: '${fmtPct(realizedHold, 1)} / ~5%',
                ),
              ]),
              const SizedBox(height: 10),
              const NoteBox(
                'Hold thực tế dao động mạnh khi ít phiếu (may rủi 95k×√n). '
                'Người chơi càng cược nhiều, hold thực tế càng hội tụ về '
                'biên lý thuyết — nhà cái không cần thắng từng phiếu, '
                'chỉ cần n tăng.',
                icon: Icons.insights,
              ),
              SectionTitle('Sổ kèo vòng ${g.roundNumber} — '
                  'thông tin NGƯỜI CHƠI KHÔNG THẤY'),
              for (final m in g.matches) AdminBookInsight(match: m),
              const SectionTitle('Luật vận hành nhà cái'),
              const NoteBox(
                'Odds = xác suất thật × 0.95 → mỗi kèo cài sẵn hold ~5%, '
                'kèo xiên nhân biên theo số chân (1 − 0.95^k). Nhà cái thật '
                'còn 4 công cụ giữ sổ cân: chỉnh odds theo dòng tiền, trần '
                'cược, kèo chấp, và đẩy kèo (lay off) sang nhà cái khác.',
                icon: Icons.gavel,
              ),
              const SectionTitle('Logic & công thức (tài liệu gốc)'),
              for (final t in _topics)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: Icon(t.$2, color: scheme.primary),
                    title: Text(t.$1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => t.$3())),
                  ),
                ),
              const SectionTitle('FCM device token — test push từ Console'),
              ValueListenableBuilder<String?>(
                valueListenable: NotificationService.instance.fcmToken,
                builder: (_, token, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SelectableText(
                      token ??
                          'Chưa có token — Firebase chưa cấu hình '
                              '(thiếu google-services.json) hoặc chưa cấp quyền thông báo.',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('Xem sàn kèo như người chơi'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SportsbookScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
