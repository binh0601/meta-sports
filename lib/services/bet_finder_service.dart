import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../logic/bet_query_filter.dart';
import '../logic/bet_query_parser.dart';
import '../logic/football_market.dart';

/// Dich cau hoi tim keo tu nhien thanh BetQueryFilter. Co GROQ_API_KEY ->
/// goi Groq yeu cau tra JSON dung schema; khong key / loi / sai format ->
/// fallback BetQueryParser (luon co ket qua, khong bao gio throw).
class BetFinderService {
  BetFinderService._();
  static final BetFinderService instance = BetFinderService._();

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static const String _systemPrompt =
      'Ban dich cau hoi tim keo bong da thanh JSON loc. Chi tra ve JSON, '
      'khong giai thich them, khong markdown. Schema: '
      '{"teamKeywords": [string], "sideHome": true|false|null, '
      '"maxOdds": number|null, "minOdds": number|null, '
      '"league": "asianCup"|"worldCup"|null}.';

  Future<BetQueryFilter> find(
      String query, List<FootballMatch> matches) async {
    if (query.trim().isEmpty) return const BetQueryFilter.empty();
    final teamNames = [for (final m in matches) ...[m.home, m.away]];
    if (_apiKey.isEmpty) return BetQueryParser.parse(query, teamNames);
    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 200,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {
                  'role': 'user',
                  'content': 'Danh sach doi dang thi dau: '
                      '${teamNames.join(", ")}. Cau hoi: "$query"'
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final content =
            (data['choices'] as List).first['message']['content'] as String;
        final stripped = stripCodeFence(content);
        return filterFromJson(jsonDecode(stripped) as Map<String, dynamic>);
      }
    } catch (_) {
      debugPrint('Bet finder Groq loi, dung parser noi bo');
    }
    return BetQueryParser.parse(query, teamNames);
  }

  /// Strip markdown code fences (```json ... ```) from Groq JSON responses.
  /// LLMs sometimes wrap JSON in fences despite instructions not to.
  static String stripCodeFence(String s) {
    final trimmed = s.trim();
    final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(trimmed);
    return fenced != null ? fenced.group(1)! : trimmed;
  }

  /// Chuyen JSON (tu Groq) thanh BetQueryFilter. Tach rieng khoi [find] de
  /// test duoc ma khong can goi mang that.
  static BetQueryFilter filterFromJson(Map<String, dynamic> json) {
    League? league;
    if (json['league'] == 'asianCup') league = League.asianCup;
    if (json['league'] == 'worldCup') league = League.worldCup;
    return BetQueryFilter(
      teamKeywords: (json['teamKeywords'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      sideHome: json['sideHome'] as bool?,
      maxOdds: (json['maxOdds'] as num?)?.toDouble(),
      minOdds: (json['minOdds'] as num?)?.toDouble(),
      league: league,
    );
  }
}
