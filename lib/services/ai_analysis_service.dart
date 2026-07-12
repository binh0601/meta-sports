import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logic/ai_match_analysis.dart';
import '../logic/football_market.dart';
import '../logic/match_insights.dart';

/// Phan tich tran bang AI. Co GROQ_API_KEY (--dart-define) -> goi Groq
/// (API chuan OpenAI); khong key / loi / timeout -> tra ban local.
/// Khong bao gio throw. Cache theo id tran trong phien.
class AiAnalysisService {
  AiAnalysisService._();
  static final AiAnalysisService instance = AiAnalysisService._();

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  final Map<int, AiMatchAnalysis> _cache = {};

  Future<AiMatchAnalysis> analyze(FootballMatch m) async {
    final cached = _cache[m.id];
    if (cached != null) return cached;
    final ins = MatchInsights.of(m);
    final local = buildLocalAnalysis(m, ins);
    if (_apiKey.isEmpty) return _cache[m.id] = local;
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
              'max_tokens': 300,
              'messages': [
                {
                  'role': 'system',
                  'content': 'Bạn là chuyên gia phân tích bóng đá. Viết '
                      'nhận định 4-5 câu tiếng Việt, giọng chuyên môn, '
                      'kết luận nghiêng về đội nào kèm %. Không markdown.'
                },
                {'role': 'user', 'content': _prompt(m, ins)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final text = ((data['choices'] as List).first['message']['content']
                as String)
            .trim();
        return _cache[m.id] = AiMatchAnalysis(
          text: '$text\n\n$kAiDisclaimer',
          homeConfidencePct: ins.expertHomePct,
          source: 'groq',
        );
      }
    } catch (_) {
      // roi ve ban local ben duoi
    }
    return _cache[m.id] = local;
  }

  String _prompt(FootballMatch m, MatchInsights ins) {
    String form(List<bool> f) =>
        f.map((w) => w ? 'T' : 'B').join('');
    return 'Trận ${m.home} vs ${m.away}. '
        'Odds: ${m.home} ${m.oddsHome} / ${m.away} ${m.oddsAway}. '
        'Chuyên gia đánh giá ${m.home} ${ins.expertHomePct}%. '
        'Phong độ 5 trận (T=thắng B=bại): ${m.home} ${form(ins.formHome)}, '
        '${m.away} ${form(ins.formAway)}. '
        'Đối đầu gần đây: ${ins.h2h.join('; ')}.';
  }
}
