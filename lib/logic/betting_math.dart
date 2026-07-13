import 'dart:math';

/// Toan bo cong thuc lay tu tai lieu "Toan hoc nha cai".
/// Don vi tien: nghin dong (k). Vi du chuan: cuoc 100k, odds 1.90, p = 50%.
class BettingMath {
  BettingMath._();

  /// Xac suat ngam cua mot muc odds: 1 / odds.
  static double impliedProb(double odds) => 1 / odds;

  /// Overround = tong xac suat ngam cua moi cua - 100%.
  static double overround(List<double> oddsList) =>
      oddsList.fold(0.0, (s, o) => s + 1 / o) - 1.0;

  /// Hold (bien tren doanh thu) = overround / (1 + overround).
  static double hold(double overroundValue) =>
      overroundValue / (1 + overroundValue);

  /// Ky vong moi van: p * lai_khi_thang - (1-p) * tien_cuoc.
  static double evPerBet({
    required double stake,
    required double odds,
    required double p,
  }) =>
      p * stake * (odds - 1) - (1 - p) * stake;

  /// Lai nha cai khi [a] / 10 nguoi dat cua A, moi nguoi 100k VND, odds 1.90.
  /// Neu A ra: thu (10 - a) * 100k, chi a * 90k  =>  1000k - 190k * a.
  static double bookProfitIfAWins(int a) => 1000000 - 190000.0 * a;

  /// Neu B ra: thu a * 100k, chi (10 - a) * 90k  =>  190k * a - 900k.
  static double bookProfitIfBWins(int a) => 190000.0 * a - 900000;

  /// Luc 1 - bien nha cai keo thang: 5k VND moi van, cong don tuyen tinh.
  static double houseDrift(num n) => 5000.0 * n;

  /// Luc 2 - dao dong may rui: do lech chuan 95k VND moi van, lon theo can n.
  static double luckSwing(num n) => 95000.0 * sqrt(n);

  /// Diem giao 2 luc: 5000n = 95000*sqrt(n)  =>  n = 361.
  static const int crossoverGames = 361;

  /// Xap xi % nguoi choi con lai sau n van: P(Z > sqrt(n) / 19).
  static double winnersShare(num n) => 1 - _phi(sqrt(n) / 19);

  /// Martingale voi odds 1.90: net sau k lan thua lien tiep roi thang (cuoc goc 100k VND)
  /// = 90k * 2^k - 100k * (2^k - 1) = 100k - 10k * 2^k (k tu lan thua thu 4 la am).
  static double martingaleNet(int k) => 100000 - 10000.0 * pow(2, k);

  /// Bien nha cai khi ghep k keo, moi keo giu lai 95% gia tri: 1 - 0.95^k.
  static double parlayMargin(int k) => 1 - pow(0.95, k).toDouble();

  /// Mo phong so du (VND) qua [n] van cuoc 100k VND, odds 1.90, p = 0.5.
  /// Tra ve duong di so du, bat dau tu 0.
  static List<double> simulateBankroll(int n, Random rng) {
    final path = List<double>.filled(n + 1, 0);
    for (var i = 1; i <= n; i++) {
      path[i] = path[i - 1] + (rng.nextBool() ? 90000 : -100000);
    }
    return path;
  }

  /// Mo phong 1 chu ky Martingale: gap doi den khi thang hoac chay tui.
  /// Tra ve so du moi (VND). [bankroll] va [baseStake] tinh bang VND.
  static ({double bankroll, int losses, bool busted}) martingaleCycle(
      double bankroll, double baseStake, Random rng) {
    var stake = baseStake;
    var losses = 0;
    while (true) {
      if (stake > bankroll) return (bankroll: bankroll, losses: losses, busted: true);
      if (rng.nextBool()) {
        return (bankroll: bankroll + stake * 0.9, losses: losses, busted: false);
      }
      bankroll -= stake;
      stake *= 2;
      losses++;
    }
  }

  // Ham phan phoi chuan tich luy, xap xi erf theo Abramowitz-Stegun 7.1.26.
  static double _phi(double z) => 0.5 * (1 + _erf(z / sqrt2));

  static double _erf(double x) {
    final sign = x < 0 ? -1.0 : 1.0;
    x = x.abs();
    const p = 0.3275911;
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    final t = 1 / (1 + p * x);
    final y =
        1 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t) * exp(-x * x);
    return sign * y;
  }
}

/// Dinh dang "VND" gon: 810000 -> "+810k", -520000 -> "-520k".
String fmtK(double v) {
  final sign = v > 0 ? '+' : '';
  if (v.abs() >= 1000000) {
    final m = v / 1000000;
    return '$sign${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)} triệu';
  }
  return '$sign${(v / 1000).round()}k';
}

/// Dinh dang so du / tien cuoc, khong keo dau "+": 9900000 -> "9,9 triệu".
String fmtMoney(double v) {
  if (v.abs() >= 1000000) {
    final m = v / 1000000;
    final s = m.toStringAsFixed(m == m.roundToDouble() ? 0 : 2);
    return '${s.replaceAll('.', ',')} triệu';
  }
  return '${(v / 1000).round()}k';
}

/// Dinh dang phan tram: 0.0526 -> "5,26%".
String fmtPct(double v, [int digits = 2]) =>
    '${(v * 100).toStringAsFixed(digits).replaceAll('.', ',')}%';

