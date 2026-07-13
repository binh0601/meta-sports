import 'dart:math';

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
  final double oddsHome;
  final double oddsAway;

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
    required this.oddsHome,
    required this.oddsAway,
  });

  String get score => played ? '$homeGoals - $awayGoals' : kickoff;

  /// Da tran nay: ket qua rut tu xac suat that, ty so chi de trang tri.
  void play(Random rng) {
    played = true;
    homeWon = rng.nextDouble() < trueProbHome;
    final winnerGoals = 1 + rng.nextInt(3);
    final loserGoals = rng.nextInt(winnerGoals);
    homeGoals = homeWon ? winnerGoals : loserGoals;
    awayGoals = homeWon ? loserGoals : winnerGoals;
  }
}

/// Mot lua chon trong phieu cuoc: doi nao cua tran nao.
class BetSelection {
  final FootballMatch match;
  final bool onHome;
  BetSelection(this.match, this.onHome);

  double get odds => onHome ? match.oddsHome : match.oddsAway;
  String get teamName => onHome ? match.home : match.away;
  bool get won => match.played && (onHome == match.homeWon);
}

/// Ket qua 1 chan cuoc sau khi thanh toan — du lieu thuan (khong tham
/// chieu FootballMatch) de luu/khoi phuc tu Firestore.
class LegResult {
  final String teamName;
  final double odds;
  final bool won;
  const LegResult(this.teamName, this.odds, this.won);

  Map<String, dynamic> toMap() =>
      {'team': teamName, 'odds': odds, 'won': won};

  factory LegResult.fromMap(Map<String, dynamic> m) => LegResult(
      m['team'] as String, (m['odds'] as num).toDouble(), m['won'] as bool);
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
      for (final s in selections) LegResult(s.teamName, s.odds, s.won)
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
    );
  });
}
