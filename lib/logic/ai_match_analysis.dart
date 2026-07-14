import 'dart:math';

import 'football_market.dart';
import 'match_insights.dart';

/// Ket qua phan tich AI cho 1 tran — nguon 'local' (sinh template)
/// hoac 'groq' (goi API that qua AiAnalysisService).
class AiMatchAnalysis {
  final String text;
  final int homeConfidencePct; // % nghieng ve doi nha (theo chuyen gia)
  final String source;
  const AiMatchAnalysis({
    required this.text,
    required this.homeConfidencePct,
    required this.source,
  });
}

/// Sinh phan tich tu du lieu soi keo co san. Seed theo id tran nen
/// cung mot tran luon ra cung mot bai — demo on dinh, chay offline.
AiMatchAnalysis buildLocalAnalysis(FootballMatch m, MatchInsights ins) {
  final rng = Random(m.id * 31);
  final favHome = ins.expertHomePct >= 50;
  final fav = favHome ? m.home : m.away;
  final dog = favHome ? m.away : m.home;
  final favPct = favHome ? ins.expertHomePct : 100 - ins.expertHomePct;
  int wins(List<bool> form) => form.where((w) => w).length;
  final favWins = wins(favHome ? ins.formHome : ins.formAway);
  final dogWins = wins(favHome ? ins.formAway : ins.formHome);

  final openers = [
    'Dựa trên dữ liệu 5 trận gần nhất và lịch sử đối đầu, ',
    'Tổng hợp phong độ hai đội và tỷ lệ đặt của cộng đồng, ',
    'Mô hình thống kê từ chuỗi trận gần đây cho thấy ',
  ];
  final verdicts = [
    '$fav đang được đánh giá cao hơn với xác suất khoảng $favPct%.',
    'cán cân đang nghiêng về $fav (khoảng $favPct%).',
    '$fav nhỉnh hơn rõ rệt với ~$favPct% cơ hội thắng.',
  ];
  final buffer = StringBuffer()
    ..write(openers[rng.nextInt(openers.length)])
    ..write(verdicts[rng.nextInt(verdicts.length)])
    ..write(' Phong độ gần đây: $fav thắng $favWins/5, '
        '$dog thắng $dogWins/5.')
    ..write(favPct >= 60
        ? ' Kèo chênh lệch — bù lại odds cho $fav sẽ thấp, '
            'ăn ít mỗi lần trúng.'
        : ' Hai đội khá cân bằng nên trận này rủi ro cao hơn.');

  return AiMatchAnalysis(
    text: buffer.toString(),
    homeConfidencePct: ins.expertHomePct,
    source: 'local',
  );
}
