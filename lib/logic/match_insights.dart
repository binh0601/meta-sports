import 'dart:math';

import 'betting_math.dart';
import 'football_market.dart';

/// Thong ke "soi keo" cho 1 tran — sinh tat dinh tu id tran nen moi lan
/// mo deu giong nhau. Diem giao duc: du lieu nay PHAN ANH DUNG xac suat
/// that (soi chuan den may cung khong thang duoc bien 5% cua nha cai).
class MatchInsights {
  final List<bool> formHome; // 5 tran gan nhat, true = thang
  final List<bool> formAway;
  final List<String> h2h; // 3 lan doi dau gan nhat
  final int expertHomePct; // "chuyen gia" = xac suat ngam chuan hoa
  final int communityHomePct; // % cong dong chon doi nha (co nhieu)

  MatchInsights._({
    required this.formHome,
    required this.formAway,
    required this.h2h,
    required this.expertHomePct,
    required this.communityHomePct,
  });

  /// Edge cam nhan: chenh lech xac suat "chuyen gia" vs xac suat ngam
  /// tu odds hien thi. KHONG phai loi nhuan that — moi keo van co EV that
  /// am ~5% vi overround. Chi ap dung y nghia voi keo 1x2 (thang/thua),
  /// khong dung cho keo chap.
  double edgeFor(bool onHome, double odds) {
    final expertProb = (onHome ? expertHomePct : 100 - expertHomePct) / 100;
    return expertProb - BettingMath.impliedProb(odds);
  }

  factory MatchInsights.of(FootballMatch m) {
    final rng = Random(m.id * 7919); // seed theo tran -> on dinh
    final p = m.trueProbHome;

    List<bool> form(double winProb) =>
        List.generate(5, (_) => rng.nextDouble() < winProb);

    // Doi dau: ket qua qua khu cung rut tu xac suat that
    String h2hLine() {
      final homeWin = rng.nextDouble() < p;
      final w = 1 + rng.nextInt(3);
      final l = rng.nextInt(w);
      return homeWin
          ? '${m.home}  $w - $l  ${m.away}'
          : '${m.home}  $l - $w  ${m.away}';
    }

    // "Chuyen gia": xac suat ngam da chuan hoa (bo bien nha cai)
    final ihome = 1 / m.oddsHome;
    final iaway = 1 / m.oddsAway;
    final expert = (ihome / (ihome + iaway) * 100).round();
    // Cong dong: quanh chuyen gia +- 12 diem (tam ly dam dong)
    final community =
        (expert + (rng.nextDouble() - .5) * 24).clamp(5, 95).round();

    return MatchInsights._(
      formHome: form(p),
      formAway: form(1 - p),
      h2h: List.generate(3, (_) => h2hLine()),
      expertHomePct: expert,
      communityHomePct: community,
    );
  }
}
