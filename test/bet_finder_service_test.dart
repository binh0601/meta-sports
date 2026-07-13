import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/services/bet_finder_service.dart';

void main() {
  group('BetFinderService._stripCodeFence', () {
    test('strip markdown fence ```json ... ```', () {
      const json = '```json\n{"key": "value"}\n```';
      final result = BetFinderService.stripCodeFence(json);
      expect(result, '{"key": "value"}');
    });

    test('strip fence without json language tag', () {
      const json = '```\n{"key": "value"}\n```';
      final result = BetFinderService.stripCodeFence(json);
      expect(result, '{"key": "value"}');
    });

    test('no fence -> return trimmed input', () {
      const json = '{"key": "value"}';
      final result = BetFinderService.stripCodeFence(json);
      expect(result, '{"key": "value"}');
    });

    test('preserve whitespace inside fence', () {
      const json = '```json\n{\n  "key": "value"\n}\n```';
      final result = BetFinderService.stripCodeFence(json);
      expect(result.contains('\n'), true);
      expect(result.contains('  '), true);
    });
  });

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

    test('teamKeywords with mixed types -> keep only strings', () {
      final f = BetFinderService.filterFromJson({
        'teamKeywords': ['Việt Nam', 42, null, 'Thái Lan', false],
      });
      expect(f.teamKeywords, ['Việt Nam', 'Thái Lan']);
    });

    test('teamKeywords empty list with non-strings -> return empty', () {
      final f = BetFinderService.filterFromJson({
        'teamKeywords': [42, null, false],
      });
      expect(f.teamKeywords, isEmpty);
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
