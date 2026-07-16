import 'package:flutter/material.dart';

import '../logic/xac_suat_game.dart';
import '../logic/xac_suat_math.dart';
import 'xac_suat_style.dart';

/// Bang dat cuoc: Tai/Xiu, Le/Chan/Dac biet, va luoi so 0–9 (Dung tong).
/// Moi lan bam = dat [stake] xu vao lua chon do (validate trong game).
class XsBetPad extends StatelessWidget {
  final XsGame game;
  final double stake;
  final void Function(XsBetKind kind, {int? exactValue}) onBet;
  const XsBetPad(
      {super.key,
      required this.game,
      required this.stake,
      required this.onBet});

  bool get _open => game.bettingOpen;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _kindTile(XsBetKind.tai, flex: 1),
        const SizedBox(width: 10),
        _kindTile(XsBetKind.xiu, flex: 1),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _kindTile(XsBetKind.le, flex: 1),
        const SizedBox(width: 10),
        _kindTile(XsBetKind.chan, flex: 1),
        const SizedBox(width: 10),
        _kindTile(XsBetKind.dacBiet, flex: 1),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        const Text('ĐÚNG TỔNG BÀN · ×9',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const Spacer(),
        Text('${game.distinctExactPicks}/$kXsMaxDistinctExactPicks số',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
        children: List.generate(10, _numberTile),
      ),
    ]);
  }

  Widget _kindTile(XsBetKind kind, {required int flex}) {
    final color = xsKindColor(kind);
    final staked = game.stakedOn(kind);
    return Expanded(
      flex: flex,
      child: Opacity(
        opacity: _open ? 1 : 0.45,
        child: Material(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _open ? () => onBet(kind) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Column(children: [
                Text(xsKindLabel(kind),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(xsKindHint(kind),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                if (staked > 0) ...[
                  const SizedBox(height: 4),
                  _stakeBadge(staked, color),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberTile(int n) {
    final color = xsNumberColor(n);
    final special = xsNumberIsSpecial(n);
    final staked = game.stakedOn(XsBetKind.dungTong, exactValue: n);
    return Opacity(
      opacity: _open ? 1 : 0.45,
      child: Material(
        color: color.withValues(alpha: 0.18),
        shape: CircleBorder(
            side: BorderSide(
                color: special ? kXsSpecial : color.withValues(alpha: 0.7),
                width: special ? 2.5 : 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _open
              ? () => onBet(XsBetKind.dungTong, exactValue: n)
              : null,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$n',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
                if (staked > 0)
                  Text('${(staked / 1000).round()}k',
                      style: TextStyle(color: color, fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stakeBadge(double staked, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${(staked / 1000).round()}k',
            style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w800)),
      );
}
