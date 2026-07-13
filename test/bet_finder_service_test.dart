import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/services/bet_finder_service.dart';

void main() {
  group('BetFinderService.filterFromJson', () {
    test('parse day du field', () {
      final f = BetFinderService.filterFromJson({
        'teamKeywords': ['Việt Nam'],
        'sideHome': true,
        'maxOdds': 2.0,
        'minOdds': null,
        'league': 'worldCup',
      });
      expect(f.teamKeywords, ['Việt Nam']);
      expect(f.sideHome, true);
      expect(f.maxOdds, 2.0);
      expect(f.minOdds, null);
      expect(f.league, League.worldCup);
    });

    test('thieu field -> mac dinh rong/null', () {
      final f = BetFinderService.filterFromJson({});
      expect(f.isEmpty, true);
    });
  });

  group('BetFinderService.find (khong co GROQ_API_KEY trong test)', () {
    test('cau hoi ro rang -> dung parser noi bo, tra dung filter', () async {
      final matches = generateRound(Random(1), 1);
      final f = await BetFinderService.instance
          .find('kèo cửa nhà dưới 3.0', matches);
      expect(f.sideHome, true);
      expect(f.maxOdds, 3.0);
    });
  });
}
