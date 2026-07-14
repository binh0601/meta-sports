import 'package:flutter/material.dart';

import '../logic/live_tv_matches.dart';
import '../theme/brand_colors.dart';
import 'motion_effects.dart';

/// The tran o danh sach "Truc tiep": doi + ty so + nhan LIVE + phut chay +
/// nut "Xem truc tiep". Bam ca the -> mo trinh phat. Phong cach toi + vang.
class LiveMatchCard extends StatelessWidget {
  final LiveMatchRun run;
  final int index; // cho hieu ung vao man so le
  final VoidCallback onTap;
  const LiveMatchCard(
      {super.key, required this.run, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = run.seed;
    return EntranceSlide(
      index: index,
      child: ScaleTap(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2749), Color(0xFF121834)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: Text(m.competition.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: .55))),
                  ),
                  m.isLive ? const _LiveBadge() : const _ReplayChip(),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _team(m.home)),
                  _scoreBox(),
                  Expanded(child: _team(m.away)),
                ]),
                if (m.isLive) ...[
                  const SizedBox(height: 12),
                  _minuteBar(context),
                ],
                const SizedBox(height: 14),
                _watchCta(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _team(String name) => Column(
        children: [
          TeamAvatar(name),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      );

  Widget _scoreBox() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: run.seed.isLive
            ? Text(run.score,
                style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kGold,
                    fontFeatures: [FontFeature.tabularFigures()]))
            : Text('VS',
                style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 18,
                    color: kGold.withValues(alpha: .8))),
      );

  Widget _minuteBar(BuildContext context) {
    final p = (run.minute / 90).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: .08),
            valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text("Phút ${run.minute}'",
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _watchCta() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [kGold, Color(0xFFD97706)]),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, size: 20, color: Color(0xFF1E1B4B)),
            SizedBox(width: 8),
            Text('Xem trực tiếp',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
          ],
        ),
      );
}

/// Avatar tron cho doi bong: chu cai dau + mau suy tu ten (khong dung emoji).
class TeamAvatar extends StatelessWidget {
  final String name;
  const TeamAvatar(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = (words.length >= 2
            ? words[0][0] + words[1][0]
            : name.substring(0, name.length >= 2 ? 2 : 1))
        .toUpperCase();
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFFF97316),
      Color(0xFFA855F7),
      Color(0xFFEF4444),
      Color(0xFF14B8A6),
    ];
    final color = palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: .6)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: Text(initials,
          style: const TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }
}

/// Nhan "● LIVE" do co cham nhap nhay.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(6)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          PulseDot(Colors.white),
          SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ]),
      );
}

/// Chip "PHÁT LẠI" cho muc khong truc tiep.
class _ReplayChip extends StatelessWidget {
  const _ReplayChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kGold.withValues(alpha: .7))),
        child: const Text('PHÁT LẠI',
            style: TextStyle(
                color: kGold,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      );
}
