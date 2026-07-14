import 'dart:math';

import 'handicap_settlement.dart';

/// Mot tran bong 2 cua (thang/thua, bo qua hoa cho don gian).
/// Odds duoc dinh gia tu xac suat that roi nhan 0.95 -> overround ~5,26%
/// dung nhu tai lieu "Toan hoc nha cai".
class FootballMatch {
  final int id;
  final String home;
  final String away;
  final String flagHome; // duong dan asset quoc ky
  final String flagAway;
  final String kickoff; // gio da hien thi, vd "19:30"
  final double trueProbHome; // xac suat that - nguoi choi KHONG nhin thay
  // Odds 1x2 nhay quanh gia goc (baseOdds) de mo phong san keo live.
  // Betting/settlement doc thang oddsHome/oddsAway hien tai.
  double oddsHome;
  double oddsAway;
  final double baseOddsHome;
  final double baseOddsAway;
  int oddsDirHome = 0; // -1 giam / 0 dung / 1 tang (cho mui ten flash)
  int oddsDirAway = 0;
  final double homeHandicap; // line chap, goc nhin home (am = home cua tren)
  final double oddsHdpHome;
  final double oddsHdpAway;
  final double oddsDraw;

  bool played = false;
  bool homeWon = false;
  int homeGoals = 0;
  int awayGoals = 0;

  FootballMatch({
    required this.id,
    required this.home,
    required this.away,
    required this.flagHome,
    required this.flagAway,
    required this.kickoff,
    required this.trueProbHome,
    required double oddsHome,
    required double oddsAway,
    required this.homeHandicap,
    required this.oddsHdpHome,
    required this.oddsHdpAway,
    required this.oddsDraw,
  })  : oddsHome = oddsHome,
        oddsAway = oddsAway,
        baseOddsHome = oddsHome,
        baseOddsAway = oddsAway;

  String get score => played ? '$homeGoals - $awayGoals' : kickoff;

  /// Nhich odds 1x2 quanh gia goc (±0.08) de san keo trong dang "chay".
  /// Ghi huong tang/giam de UI hien mui ten. Khong dong khi tran da da.
  void tickLiveOdds(Random rng) {
    if (played) return;
    double jitter(double base) {
      final t = base + (rng.nextDouble() - 0.5) * 0.12;
      final c = t.clamp(base - 0.08, base + 0.08);
      return (c * 100).roundToDouble() / 100;
    }
    final nh = jitter(baseOddsHome);
    oddsDirHome = nh.compareTo(oddsHome);
    oddsHome = nh;
    final na = jitter(baseOddsAway);
    oddsDirAway = na.compareTo(oddsAway);
    oddsAway = na;
  }

  /// Da tran nay: ket qua rut tu xac suat that qua phan phoi Poisson,
  /// ty so co the hoa vi 2 doi gan nhau ve suc manh.
  void play(Random rng) {
    played = true;
    // Ky vong ban thang suy tu trueProbHome; 2 doi gan nhau -> co hoa thuc te.
    final lambdaHome = 0.8 + trueProbHome * 1.6;
    final lambdaAway = 0.8 + (1 - trueProbHome) * 1.6;
    homeGoals = _poisson(rng, lambdaHome).clamp(0, 5);
    awayGoals = _poisson(rng, lambdaAway).clamp(0, 5);
    homeWon = homeGoals > awayGoals; // hoa -> false (giu tuong thich cu)
  }
}

/// Sinh so ban thang theo phan phoi Poisson (thuat toan Knuth).
int _poisson(Random rng, double lambda) {
  final l = exp(-lambda);
  var k = 0;
  var p = 1.0;
  do {
    k++;
    p *= rng.nextDouble();
  } while (p > l);
  return k - 1;
}

/// Line chap suy tu xac suat that: chenh lech cang lon line cang cao,
/// lam tron ve boi 0.25, doi manh la cua tren (line am ve phia ho).
double _handicapLine(double p) {
  final edge = p - 0.5;                 // -0.15..0.15
  final rawMag = edge.abs() / 0.15 * 2.0; // 0..2.0 (du loai: 0.25..2.0)
  final mag = ((rawMag / 0.25).round() * 0.25).clamp(0.0, 2.0); // boi 0.25
  return edge >= 0 ? -mag : mag;        // home manh -> line am
}

/// Loai keo: 1x2 (thang/thua goc) hoac chap chau A (Asian Handicap).
enum MarketType { match1x2, handicap }

/// Mot lua chon trong phieu cuoc: doi nao cua tran nao, thi truong nao.
class BetSelection {
  final FootballMatch match;
  final bool onHome;
  final MarketType market;
  BetSelection(this.match, this.onHome, {this.market = MarketType.match1x2});

  /// Line chap theo goc nhin cua lua chon nay (chi co y nghia khi
  /// market == handicap).
  double get line => onHome ? match.homeHandicap : -match.homeHandicap;

  double get odds => market == MarketType.handicap
      ? (onHome ? match.oddsHdpHome : match.oddsHdpAway)
      : (onHome ? match.oddsHome : match.oddsAway);
  String get teamName => onHome ? match.home : match.away;
  bool get won =>
      match.played &&
      match.homeGoals != match.awayGoals &&
      (onHome == match.homeWon);
}

/// Ket qua 1 chan cuoc sau khi thanh toan — du lieu thuan (khong tham
/// chieu FootballMatch) de luu/khoi phuc tu Firestore.
class LegResult {
  final String teamName;
  final double odds;
  final bool won;
  final double payoutRatio;
  final MarketType market;
  final SettleStatus status;

  const LegResult(
    this.teamName,
    this.odds,
    this.won, {
    this.payoutRatio = 0.0,
    this.market = MarketType.match1x2,
    this.status = SettleStatus.lose,
  });

  Map<String, dynamic> toMap() => {
        'team': teamName,
        'odds': odds,
        'won': won,
        'payoutRatio': payoutRatio,
        'market': market.name,
        'status': status.name,
      };

  /// Doc cu (truoc B3) chi co team/odds/won -> suy payoutRatio/status tu won,
  /// market mac dinh 1x2. Doc moi doc thang field da luu.
  factory LegResult.fromMap(Map<String, dynamic> m) {
    final won = m['won'] as bool;
    final odds = (m['odds'] as num).toDouble();
    final payoutRatio =
        (m['payoutRatio'] as num?)?.toDouble() ?? (won ? odds : 0.0);
    final market = MarketType.values.firstWhere(
      (e) => e.name == m['market'],
      orElse: () => MarketType.match1x2,
    );
    final status = SettleStatus.values.firstWhere(
      (e) => e.name == m['status'],
      orElse: () => won ? SettleStatus.win : SettleStatus.lose,
    );
    return LegResult(
      m['team'] as String,
      odds,
      won,
      payoutRatio: payoutRatio,
      market: market,
      status: status,
    );
  }
}

/// Phieu cuoc: 1 lua chon = keo don, nhieu lua chon = keo xien
/// (phai trung TAT CA moi an, odds nhan voi nhau).
/// [selections] dung khi phieu con song trong vong hien tai;
/// [legResults] duoc gan khi thanh toan (hoac khoi phuc tu cloud).
class BetSlip {
  final List<BetSelection> selections;
  final double stake; // nghin dong
  final int round;

  bool settled = false;
  bool won = false;
  double payout = 0;
  List<LegResult> legResults = [];

  BetSlip({required this.selections, required this.stake, required this.round});

  /// Dung lai phieu da co ket qua (khoi phuc lich su tu Firestore).
  factory BetSlip.restored({
    required List<LegResult> legResults,
    required double stake,
    required int round,
    required bool won,
    required double payout,
  }) {
    final b = BetSlip(selections: const [], stake: stake, round: round)
      ..settled = true
      ..won = won
      ..payout = payout
      ..legResults = legResults;
    return b;
  }

  int get legs =>
      selections.isNotEmpty ? selections.length : legResults.length;
  double get totalOdds => selections.isNotEmpty
      ? selections.fold(1.0, (p, s) => p * s.odds)
      : legResults.fold(1.0, (p, l) => p * l.odds);
  double get net => payout - stake;

  /// Chot ket qua tung chan tu selections (goi khi thanh toan).
  void captureLegResults() {
    legResults = [
      for (final s in selections)
        LegResult(
          s.teamName,
          s.odds,
          s.won,
          payoutRatio: s.won ? s.odds : 0.0,
          market: s.market,
          status: s.won ? SettleStatus.win : SettleStatus.lose,
        ),
      // leg handicap se duoc B4 tinh lai theo settleHandicap
    ];
  }
}

/// 16 doi tuyen chau A — dung quoc ky that trong assets/flags/.
const List<(String, String)> _teams = [
  ('Việt Nam', 'vn'),
  ('Thái Lan', 'th'),
  ('Nhật Bản', 'jp'),
  ('Hàn Quốc', 'kr'),
  ('Trung Quốc', 'cn'),
  ('Úc', 'au'),
  ('Ả Rập Xê Út', 'sa'),
  ('Iran', 'ir'),
  ('Qatar', 'qa'),
  ('Uzbekistan', 'uz'),
  ('Iraq', 'iq'),
  ('UAE', 'ae'),
  ('Malaysia', 'my'),
  ('Indonesia', 'id'),
  ('Oman', 'om'),
  ('Jordan', 'jo'),
];

/// Giai dau: 2 pool doi khac nhau, cung co che odds.
enum League { asianCup, worldCup }

extension LeagueInfo on League {
  String get label =>
      this == League.asianCup ? 'CUP CHÂU Á 2026' : 'WORLD CUP 2026';
}

/// 16 doi Au-My cho World Cup — co tai tu flagcdn (Task 1).
const List<(String, String)> _wcTeams = [
  ('Đức', 'de'), ('Pháp', 'fr'), ('Anh', 'gb-eng'), ('Tây Ban Nha', 'es'),
  ('Ý', 'it'), ('Bồ Đào Nha', 'pt'), ('Hà Lan', 'nl'), ('Bỉ', 'be'),
  ('Croatia', 'hr'), ('Đan Mạch', 'dk'), ('Brazil', 'br'),
  ('Argentina', 'ar'), ('Uruguay', 'uy'), ('Mỹ', 'us'),
  ('Mexico', 'mx'), ('Morocco', 'ma'),
];

const List<String> _kickoffSlots = [
  '17:00', '18:00', '19:30', '20:00', '21:00', '21:30', '22:00', '23:15',
];

/// Sinh 1 vong dau 8 tran, boc tham 16 doi tuyen ngau nhien.
List<FootballMatch> generateRound(Random rng, int startId, {League league = League.asianCup}) {
  final pool = league == League.worldCup ? _wcTeams : _teams;
  final teams = [...pool]..shuffle(rng);
  double round2(double v) => (v * 100).roundToDouble() / 100;
  return List.generate(8, (i) {
    final p = 0.35 + rng.nextDouble() * 0.30; // xac suat that 35%..65%
    final home = teams[i * 2];
    final away = teams[i * 2 + 1];
    final hdp = _handicapLine(p);
    return FootballMatch(
      id: startId + i,
      home: home.$1,
      away: away.$1,
      flagHome: 'assets/flags/${home.$2}.png',
      flagAway: 'assets/flags/${away.$2}.png',
      kickoff: _kickoffSlots[i],
      trueProbHome: p,
      oddsHome: round2(0.95 / p),
      oddsAway: round2(0.95 / (1 - p)),
      homeHandicap: hdp,
      oddsHdpHome: round2(1.90 + (rng.nextDouble() - .5) * .1),
      oddsHdpAway: round2(1.90 + (rng.nextDouble() - .5) * .1),
      oddsDraw: round2(0.95 / 0.26), // pDraw ~26%
    );
  });
}
