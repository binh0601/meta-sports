import 'football_market.dart';

const String _from =
    'aàáạảãăằắặẳẵâầấậẩẫeèéẹẻẽêềếệểễiìíịỉĩoòóọỏõôồốộổỗơờớợởỡ'
    'uùúụủũưừứựửữyỳýỵỷỹđ';
const String _to =
    'aaaaaaaaaaaaaaaaaaeeeeeeeeeeeeiiiiiioooooooooooooooooo'
    'uuuuuuuuuuuuyyyyyyd';

/// Bo dau tieng Viet + ha chu thuong — dung chung cho so khop tu khoa
/// khong phan biet dau (parser lan bo loc).
String normalizeVi(String s) {
  var out = s.toLowerCase();
  for (var i = 0; i < _from.length; i++) {
    out = out.replaceAll(_from[i], _to[i]);
  }
  return out;
}

/// Bo loc rut ra tu cau hoi tim keo tu nhien — dung chung cho ca parser
/// noi bo va ket qua Groq tra ve. Rong (moi field null/list rong) = khong
/// loc gi, hien tat ca.
class BetQueryFilter {
  final List<String> teamKeywords;
  final bool? sideHome; // null = ca 2 cua
  final double? maxOdds;
  final double? minOdds;
  final League? league;

  const BetQueryFilter({
    this.teamKeywords = const [],
    this.sideHome,
    this.maxOdds,
    this.minOdds,
    this.league,
  });

  const BetQueryFilter.empty() : this();

  bool get isEmpty =>
      teamKeywords.isEmpty &&
      sideHome == null &&
      maxOdds == null &&
      minOdds == null &&
      league == null;

  /// True neu cua [onHome] cua tran [m] thoa moi dieu kien filter.
  /// [currentLeague]: giai dang hien thi tren san keo.
  bool matchesSide(FootballMatch m, bool onHome, League currentLeague) {
    if (league != null && league != currentLeague) return false;
    if (sideHome != null && sideHome != onHome) return false;
    final odds = onHome ? m.oddsHome : m.oddsAway;
    if (maxOdds != null && odds > maxOdds!) return false;
    if (minOdds != null && odds < minOdds!) return false;
    if (teamKeywords.isNotEmpty) {
      final team = normalizeVi(onHome ? m.home : m.away);
      final ok = teamKeywords.any((k) => team.contains(normalizeVi(k)));
      if (!ok) return false;
    }
    return true;
  }
}
