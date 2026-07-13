import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/match_insights.dart';

void main() {
  group('MatchInsights.edgeFor', () {
    test('odds dung dung xac suat that -> edge ~0', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      // expertHomePct duoc suy tu chinh oddsHome/oddsAway (da chuan hoa bo
      // overround), nen dung lai odds that cua tran se luon cho edge am nhe
      // (khoang -1.7% den -3.4% tuy p) — khong bao gio duong, vi overround
      // luon lam impliedProb (odds that) > expertProb (da chuan hoa).
      final edgeHome = ins.edgeFor(true, m.oddsHome);
      final edgeAway = ins.edgeFor(false, m.oddsAway);
      expect(edgeHome, lessThan(0));
      expect(edgeHome, greaterThan(-0.06));
      expect(edgeAway, lessThan(0));
      expect(edgeAway, greaterThan(-0.06));
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
