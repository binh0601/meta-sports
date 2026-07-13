import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/match_insights.dart';

void main() {
  group('MatchInsights.edgeFor', () {
    test('odds dung dung xac suat that -> edge ~0', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      // expertHomePct suy tu chinh odds hien tai (khong overround-adjust
      // rieng) nen edge cho ca 2 cua phai gan 0.
      expect(ins.edgeFor(true, m.oddsHome).abs(), lessThan(0.001));
      expect(ins.edgeFor(false, m.oddsAway).abs(), lessThan(0.001));
    });

    test('odds cao hon xac suat ngam that -> edge duong', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      // Odds gia dinh cao hon (it "hoi" hon) -> xac suat ngam thap hon
      // expert -> edge duong.
      final inflatedOdds = m.oddsHome * 1.2;
      expect(ins.edgeFor(true, inflatedOdds), greaterThan(0));
    });

    test('odds thap hon xac suat ngam that -> edge am', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      final deflatedOdds = m.oddsHome * 0.8;
      expect(ins.edgeFor(true, deflatedOdds), lessThan(0));
    });
  });
}
