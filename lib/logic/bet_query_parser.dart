import 'bet_query_filter.dart';
import 'football_market.dart';

/// Parser tu ngu rule-based cho cau hoi tim keo tieng Viet — chay hoan
/// toan offline, dung khi khong co GROQ_API_KEY hoac goi LLM that bai.
class BetQueryParser {
  BetQueryParser._();

  /// Check if [phrase] appears as whole words in [query] (not as a substring
  /// of a longer word). This prevents false positives for short team names.
  /// For example, team 'Ý' (normalized to 'y') should not match inside 'nay'
  /// (today), and team 'Úc' (normalized to 'uc') should not match inside
  /// 'được' (normalized to 'duoc').
  static bool _containsWholeWords(String query, String phrase) {
    final queryWords = query.split(RegExp(r'\s+'));
    final phraseWords = phrase.split(RegExp(r'\s+'));
    if (phraseWords.isEmpty) return false;
    for (var i = 0; i + phraseWords.length <= queryWords.length; i++) {
      if (queryWords.sublist(i, i + phraseWords.length).join(' ') ==
          phraseWords.join(' ')) {
        return true;
      }
    }
    return false;
  }

  /// [teamNames]: ten doi dang hien thi trong vong dau hien tai — dung de
  /// nhan dien tu khoa ten doi trong cau hoi.
  static BetQueryFilter parse(String query, List<String> teamNames) {
    final q = normalizeVi(query);
    if (q.trim().isEmpty) return const BetQueryFilter.empty();

    bool? sideHome;
    if (q.contains('cua nha') ||
        q.contains('doi nha') ||
        q.contains('chu nha')) {
      sideHome = true;
    } else if (q.contains('cua khach') || q.contains('doi khach')) {
      sideHome = false;
    }

    double? maxOdds;
    final duoi = RegExp(r'duoi\s+(\d+(?:[.,]\d+)?)').firstMatch(q);
    if (duoi != null) {
      maxOdds = double.parse(duoi.group(1)!.replaceAll(',', '.'));
    }
    double? minOdds;
    final tren = RegExp(r'tren\s+(\d+(?:[.,]\d+)?)').firstMatch(q);
    if (tren != null) {
      minOdds = double.parse(tren.group(1)!.replaceAll(',', '.'));
    }

    League? league;
    if (q.contains('world cup')) {
      league = League.worldCup;
    } else if (q.contains('chau a') || q.contains('asian cup')) {
      league = League.asianCup;
    }

    final teamKeywords = teamNames
        .where((t) => _containsWholeWords(q, normalizeVi(t)))
        .toList();

    return BetQueryFilter(
      teamKeywords: teamKeywords,
      sideHome: sideHome,
      maxOdds: maxOdds,
      minOdds: minOdds,
      league: league,
    );
  }
}
