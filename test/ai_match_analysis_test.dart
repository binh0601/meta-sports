import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/ai_match_analysis.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/match_insights.dart';

void main() {
  FootballMatch sample() => generateRound(Random(1), 1).first;

  test('phan tich tat dinh: cung tran -> cung van ban', () {
    final m = sample();
    final a1 = buildLocalAnalysis(m, MatchInsights.of(m));
    final a2 = buildLocalAnalysis(m, MatchInsights.of(m));
    expect(a1.text, a2.text);
    expect(a1.source, 'local');
  });

  test('luon kem disclaimer va nhac ten doi duoc danh gia cao hon', () {
    final m = sample();
    final ins = MatchInsights.of(m);
    final a = buildLocalAnalysis(m, ins);
    expect(a.text, contains(kAiDisclaimer));
    final fav = ins.expertHomePct >= 50 ? m.home : m.away;
    expect(a.text, contains(fav));
    expect(a.homeConfidencePct, ins.expertHomePct);
  });
}
