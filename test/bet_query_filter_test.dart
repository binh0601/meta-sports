import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/bet_query_filter.dart';
import 'package:house_edge_demo/logic/football_market.dart';

void main() {
  group('normalizeVi', () {
    test('bo dau + ha chu thuong', () {
      expect(normalizeVi('Việt Nam'), 'viet nam');
      expect(normalizeVi('ĐỨC'), 'duc');
    });
  });

  group('BetQueryFilter.matchesSide', () {
    final matches = generateRound(Random(1), 1);
    final m = matches.first;

    test('filter rong -> luon khop', () {
      const f = BetQueryFilter.empty();
      expect(f.isEmpty, true);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), true);
    });

    test('loc theo cua nha/khach', () {
      const f = BetQueryFilter(sideHome: true);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), false);
    });

    test('loc theo khoang odds', () {
      final f = BetQueryFilter(maxOdds: m.oddsHome - 0.01);
      expect(f.matchesSide(m, true, League.asianCup), false);
      final f2 = BetQueryFilter(minOdds: m.oddsHome + 0.01);
      expect(f2.matchesSide(m, true, League.asianCup), false);
    });

    test('loc theo giai khac giai dang xem -> khong khop', () {
      const f = BetQueryFilter(league: League.worldCup);
      expect(f.matchesSide(m, true, League.asianCup), false);
      expect(f.matchesSide(m, true, League.worldCup), true);
    });

    test('loc theo ten doi (khong phan biet dau/hoa thuong)', () {
      final f = BetQueryFilter(teamKeywords: [m.home.toUpperCase()]);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), false);
    });
  });
}
