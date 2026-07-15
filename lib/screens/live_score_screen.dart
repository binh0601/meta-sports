import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/live_tv_matches.dart';
import '../theme/brand_colors.dart';
import '../widgets/live_match_card.dart';
import '../widgets/motion_effects.dart';
import 'match_live_screen.dart';

/// Man "Truc tiep": danh sach cac tran dang phat. Phut/ty so tu tang cho
/// sinh dong. Bam 1 tran -> mo trinh phat video. Vao tu icon live_tv tren
/// AppBar sportsbook (push -> Timer chi chay khi man mo).
class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  final _rng = Random();
  late final List<LiveMatchRun> _runs =
      kLiveMatches.map((m) => LiveMatchRun(m)).toList();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Moi 2.5s: tien phut + thi thoang ghi ban -> danh sach nhu app that.
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      setState(() {
        for (final r in _runs) {
          r.tick(_rng);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _liveCount => _runs.where((r) => r.seed.isLive).length;

  void _open(LiveMatchRun r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchLiveScreen(match: r.seed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient)),
        title: const Text('Trực tiếp',
            style: TextStyle(
                fontFamily: kDisplayFont, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              itemCount: _runs.length,
              itemBuilder: (_, i) => LiveMatchCard(
                run: _runs[i],
                index: i,
                onTap: () => _open(_runs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          const PulseDot(Colors.redAccent),
          const SizedBox(width: 8),
          Text('$_liveCount trận đang trực tiếp',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 14)),
          const Spacer(),
          Text('Chỉ xem',
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: .5))),
        ],
      ),
    );
  }
}
