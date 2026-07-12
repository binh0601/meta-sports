import 'package:flutter/material.dart';

import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../logic/match_insights.dart';
import '../theme/brand_colors.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/match_card.dart' show OddsSelectButton;
import '../widgets/stat_card.dart';

/// Chi tiet tran dau: phong do, doi dau, nhan dinh, % cong dong —
/// du lieu "soi keo" nhin rat thuyet phuc, nhung odds da tru san bien.
class MatchDetailScreen extends StatelessWidget {
  final FootballMatch match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final ins = MatchInsights.of(match);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết trận đấu'),
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: kHeroGradient)),
      ),
      body: ListenableBuilder(
        listenable: gameState,
        builder: (context, _) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _hero(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!match.played) ...[
                    Row(children: [
                      Expanded(
                          child: OddsSelectButton(
                              match: match, onHome: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: OddsSelectButton(
                              match: match, onHome: false)),
                    ]),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Chọn cửa tại đây rồi về tab Trận đấu để đặt phiếu',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ],
                  const SectionTitle('Nhận định chuyên gia'),
                  _splitBar(context, ins.expertHomePct,
                      leftLabel: '${ins.expertHomePct}% ${match.home}',
                      rightLabel:
                          '${match.away} ${100 - ins.expertHomePct}%'),
                  const SectionTitle('AI nhận định'),
                  AiAnalysisCard(match: match),
                  const SectionTitle('Phong độ 5 trận gần nhất'),
                  _formRow(context, match.home, match.flagHome, ins.formHome),
                  const SizedBox(height: 8),
                  _formRow(context, match.away, match.flagAway,
                      ins.formAway),
                  const SectionTitle('Đối đầu gần đây'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final line in ins.h2h)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Text(line,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SectionTitle('Cộng đồng đang đặt'),
                  _splitBar(context, ins.communityHomePct,
                      leftLabel: '${ins.communityHomePct}% chọn ${match.home}',
                      rightLabel:
                          '${100 - ins.communityHomePct}% chọn ${match.away}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header gradient: 2 co lon, ten doi, gio da / ty so.
  Widget _hero(BuildContext context) {
    Widget team(String name, String flag) => Expanded(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(flag,
                      width: 72, height: 48, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white)),
            ],
          ),
        );

    return Stack(
      children: [
        // Anh san van dong that lam nen, phu gradient xanh de chu noi
        Positioned.fill(
          child: Image.asset('assets/images/stadium_night.jpg',
              fit: BoxFit.cover),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB32563EB), Color(0xE61E1B4B)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
        children: [
          Text('CUP CHÂU Á • HÔM NAY',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: .7))),
          const SizedBox(height: 12),
          Row(
            children: [
              team(match.home, match.flagHome),
              Column(
                children: [
                  Text(
                    match.played
                        ? '${match.homeGoals} - ${match.awayGoals}'
                        : match.kickoff,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kGold),
                  ),
                  Text(match.played ? 'KẾT THÚC' : 'GIỜ ĐÁ',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: Colors.white.withValues(alpha: .6))),
                ],
              ),
              team(match.away, match.flagAway),
            ],
          ),
        ],
          ),
        ),
      ],
    );
  }

  /// Thanh chia 2 mau the hien ty le % giua 2 doi.
  Widget _splitBar(BuildContext context, int homePct,
      {required String leftLabel, required String rightLabel}) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: homePct,
                child: Container(height: 14, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 100 - homePct,
                child: Container(height: 14, color: const Color(0xFFF97316)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF93C5FD))),
            Text(rightLabel,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFFDBA74))),
          ],
        ),
      ],
    );
  }

  /// Hang phong do: co + ten + 5 cham T/B.
  Widget _formRow(
      BuildContext context, String name, String flag, List<bool> form) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child:
              Image.asset(flag, width: 24, height: 16, fit: BoxFit.cover),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600))),
        for (final won in form)
          Container(
            margin: const EdgeInsets.only(left: 4),
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: won ? const Color(0xFF16A34A) : scheme.errorContainer,
            ),
            child: Text(won ? 'T' : 'B',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: won ? Colors.white : scheme.onErrorContainer)),
          ),
      ],
    );
  }
}
