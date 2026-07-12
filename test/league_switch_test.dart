import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/game_state.dart';

void main() {
  test('generateRound theo giai: world cup ra doi Au-My', () {
    final wc = generateRound(Random(1), 1, league: League.worldCup);
    final teams = wc.expand((m) => [m.home, m.away]).toSet();
    expect(teams.contains('Đức'), true);
    expect(teams.contains('Brazil'), true);
    expect(teams.contains('Việt Nam'), false);
    expect(wc.length, 8);
  });

  test('switchLeague doi tran, giu vi, clear slip', () {
    final g = GameState();
    g.toggleSelection(g.matches.first, true);
    final balanceBefore = g.balance;
    expect(g.switchLeague(League.worldCup), true);
    expect(g.league, League.worldCup);
    expect(g.slip, isEmpty);
    expect(g.balance, balanceBefore);
    final teams = g.matches.expand((m) => [m.home, m.away]).toSet();
    expect(teams.contains('Việt Nam'), false);
  });

  test('con phieu pending -> khong cho doi giai', () {
    final g = GameState();
    g.toggleSelection(g.matches.first, true);
    g.setStake(100);
    g.placeBet();
    expect(g.switchLeague(League.worldCup), false);
    expect(g.league, League.asianCup);
  });
}
