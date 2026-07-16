import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/xac_suat_game.dart';
import '../theme/brand_colors.dart';
import 'xac_suat_style.dart';

/// Bang "tran chop nhoang": dem nguoc khi dang nhan keo / da khoa, va reveal
/// ty so 2 doi khi mo ket qua. Tong ban = con so quyet dinh thang/thua.
class XsResultBoard extends StatelessWidget {
  final XsGame game;
  const XsResultBoard({super.key, required this.game});

  // Ten doi theo seq cho co khong khi tran dau (trang tri).
  static const _teams = [
    'Rồng Đỏ', 'Sư Tử', 'Đại Bàng', 'Bão Xanh', 'Chiến Mã',
    'Hổ Vàng', 'Cá Mập', 'Sói Đêm', 'Phượng Hoàng', 'Báo Đen',
  ];
  String _home() => _teams[game.seq % _teams.length];
  String _away() => _teams[(game.seq + 3) % _teams.length];

  @override
  Widget build(BuildContext context) {
    final resolved = game.phase == XsPhase.resolved && game.lastResult != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: resolved ? _reveal(context) : _pending(context),
    );
  }

  Widget _pending(BuildContext context) {
    final locked = game.phase == XsPhase.locked;
    final secs = (game.remainingMs / 1000).ceil();
    return Column(children: [
      _matchupRow(vs: 'VS'),
      const SizedBox(height: 16),
      Text(locked ? 'ĐÃ KHOÁ KÈO' : 'ĐANG NHẬN KÈO',
          style: TextStyle(
              color: locked ? kXsTai : kXsLe,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 12)),
      const SizedBox(height: 6),
      Text('$secs',
          style: displayStyle(size: 56, color: Colors.white, spacing: 0)),
      Text(locked ? 'giây · chờ mở kết quả' : 'giây · còn đặt được',
          style: TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _reveal(BuildContext context) {
    final r = game.lastResult!;
    final win = r.netChange > 0;
    return Column(children: [
      _matchupRow(vs: '${r.homeGoals} – ${r.awayGoals}'),
      const SizedBox(height: 14),
      Text('TỔNG BÀN THẮNG',
          style: TextStyle(
              color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 6),
      Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: xsNumberColor(r.result).withValues(alpha: 0.22),
          border: Border.all(
              color: xsNumberIsSpecial(r.result)
                  ? kXsSpecial
                  : xsNumberColor(r.result),
              width: 3),
        ),
        child: Text('${r.result}',
            style: displayStyle(size: 44, color: Colors.white, spacing: 0)),
      ),
      const SizedBox(height: 10),
      _resultTags(r.result),
      if (r.hadBets) ...[
        const SizedBox(height: 10),
        Text(win ? '🎉 Trúng! ${fmtK(r.netChange)}' : '💸 Trượt ${fmtK(r.netChange)}',
            style: TextStyle(
                color: win ? kXsLe : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    ]);
  }

  Widget _matchupRow({required String vs}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(_home(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(vs,
                style: displayStyle(size: 20, color: kGold, spacing: 0)),
          ),
          Expanded(
              child: Text(_away(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15))),
        ],
      );

  Widget _resultTags(int result) {
    final tags = <String>[
      result >= 5 ? 'TÀI' : 'XỈU',
      result.isOdd ? 'LẺ' : 'CHẴN',
      if (xsNumberIsSpecial(result)) 'ĐẶC BIỆT',
    ];
    return Wrap(
      spacing: 6,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ))
          .toList(),
    );
  }
}
